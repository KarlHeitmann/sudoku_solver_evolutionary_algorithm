require_relative 'population'

#require 'byebug'

MAX_GEN = 10
ROW_SIZE = 9
POPULATION = 10
ELIMINATE = 2


BOARD = [
  [0,0,4,0,0,0,0,9,0],
  [7,0,0,0,6,0,0,0,5],
  [0,9,0,5,4,1,8,7,2],
  [0,0,0,1,8,7,0,4,0],
  [2,4,3,6,0,5,1,8,7],
  [0,8,0,3,2,4,0,0,0],
  [9,2,1,8,7,6,0,5,0],
  [6,0,0,0,1,0,0,0,8],
  [0,3,0,0,0,0,7,0,0]
]

tablero_flat = BOARD.flatten


def criss_cross(dad, mom)
  genes_dad = dad.get_genotype
  genes_mom = mom.get_genotype

  return Individual.new({ dad: genes_dad, mom: genes_mom})
end

def poblacion_inicial(tablero)
  individuals =  []
  POPULATION.times do |i|
    genes = []
    tablero.each do |f|
      casillas = []
      f.each do |e|
        if e == 0
          casillas << Cell.new(0, false)
        else
          casillas << Cell.new(e, true)
        end
      end
      genes << Chromosome.new({ vector_cells: casillas })
    end
    individuals << Individual.new({genes: genes})
  end
  return individuals
end

def test
  individuals = poblacion_inicial BOARD
  i=0
  individuals.each do |individuo|
    individuo.display

    individuo.fill_cells

    individuo.display

    puts "Indiv #{i}: #{individuo.calculate_weighted_adaptation}"
  end

  hijo = criss_cross(individuals[0], individuals[1])
  hijo.display
  puts " hijo #{0}: #{hijo.calculate_weighted_adaptation}"

  hijo.mutate
  hijo.display
  puts " hijo #{0}: #{hijo.calculate_weighted_adaptation}"
end

# Beginning of algorithm
#
# We generate the initial population from the data board. The initial population
# is chosen randomyle, respecting the fixed cells that were defined on the BOARD
# array constant.

individuals = poblacion_inicial BOARD
individuals.each do |indiv|
  indiv.fill_cells
end

#
# Here begins the loop
#
MAX_GEN.times do |i|
  #
  # EVALUATION
  #
  # Individuals of the population are evaluated according the rules on
  # "population.rb" file
  #
  total_score = 0.0
  total_cumulated  = 0.0

  individuals.each do |indiv|
    total_score += indiv.calculate_weighted_adaptation.to_f
  end
  individuals.each do |indiv|
    indiv.set_score total_score
    total_cumulated = indiv.set_cumulative_score total_cumulated
  end

  if i == 0
    #puts "Tablero inicial, los ceros representan las casillas vacias"
    puts "Initial board, zeros represent the empty cells"
    individuals.first.display
    record = Float::INFINITY
    winner = nil
    individuals.each do |indiv|
      if indiv.adaptation < record
        record = indiv.adaptation
        winner = indiv
      end
    end

    puts ""
    puts "Better adaptation: #{record}"
    winner.display
  end

  #puts individuals.count

  puts "Total score: " + total_score.to_s
  puts "Total cumulated:  " + total_cumulated.to_s
  #
  # SELECTION
  #
  # By the rulet method, some individuals are chosen to be elimminated from the
  # population. These individuals selected are the ones with greater score,
  # since this is a problem of minimization
  #
  # TODO: On this selection there is no filter that will make another drawn
  # lottery if the chosen individual has already been eliminated
  #

  ELIMINATE.times do |i|
    sorteo = rand
    individuals.delete_if do |indiv|
      (sorteo > (indiv.cumulative_score - indiv.score) and (sorteo < indiv.cumulative_score))
    end
  end

  # puts individuals.count

  #
  # REPRODUCTION
  #
  # It is used the criss_cross function defined on this fill in order to
  # randomly choose two individuals and cross them to generate offspring
  #

  ELIMINATE.times do |i|
    dad = rand(0...individuals.count)
    mom = rand(0...individuals.count)
    while (mom == dad) do
      mom = rand(0..individuals.count)
    end
    individuals << criss_cross(individuals[dad], individuals[mom])
  end

  #
  # MUTATION
  #
  # Finally, the whole population is examined, and in each individual de mutate
  # method is called. With a low probability, the individual will mutate one of
  # it's genes
  #
  # Por ultimo, se recorre toda la poblacion y se invoca el metodo mutar de cada
  # individuo. Con una baja probabiliddad, el individuo mutara uno de sus genes
  #

  individuals.each do |indiv|
    indiv.mutate
  end
end

#
# FiINAL EVALUATION
#
# Individuals of the last generation are evaluated
#
total_score = 0.0
total_cumulated  = 0.0

individuals.each do |indiv|
  total_score += indiv.calculate_weighted_adaptation.to_f
end
individuals.each do |indiv|
  indiv.set_score total_score
  total_cumulated = indiv.set_cumulative_score total_cumulated
end


record = Float::INFINITY
winner = nil
individuals.each do |indiv|
  if indiv.adaptation < record
    record = indiv.adaptation 
    winner = indiv
  end
end
puts ""
puts "Mejor adaptacion final: #{record}"
winner.display

