require 'awesome_print'

CROSSING_POINT = 4
ODDS_MUTATION = 0.8

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end

class Cell
  attr_accessor :value, :fixed

  def initialize(_value, _fixed)
    @value = _value #cell value from sudoku
    @fixed = _fixed #whether it is a fixed position or not
  end

end

class Chromosome
  def initialize(params = {})
    if params.has_key? :vector_cells
      @genes = []
      params[:vector_cells].each do |cell|
        if cell.class == Cell
          @genes << cell
        else
          raise ErrorCreateCell
        end
      end
    elsif (params.has_key?(:dad) && params.has_key?(:mom))
      @genes = []
      9.times do |i|
        if i < CROSSING_POINT
          @genes << Cell.new(params[:dad][i].value, params[:dad][i].fixed)
        else
          @genes << Cell.new(params[:mom][i].value, params[:mom][i].fixed)
        end
      end
    else
      raise ErrorCreateChromosome
    end
  end

  def display
    i=1
    row="| "
    @genes.each do |c|
      if c.fixed
        if (i%3) == 0
          row += green(c.value.to_s) + " | "
        else
          row += green(c.value.to_s) + " "
        end
      else
        if (i%3) == 0
          row += c.value.to_s + " | "
        else
          row += c.value.to_s + " "
        end
      end
      i+=1
    end
    puts row
  end

  def find_fixed_nums
    results = []
    i = 0
    @genes.each do |c|
      if c.fixed
        results << {value: c.value, index: i}
      end
      i += 1
    end
    return results
  end

  def set_value(_val, _i)
    @genes[_i] = Cell.new(_val, false) unless @genes[_i].fixed
  end

  # TODO deprecated, it is used overrided method:[] for this function
  def show_cell(i)
    return @genes[i]
  end


  def [](i)
    return @genes[i]
  end

end

class Individual
  attr_reader :adaptation, :score, :cumulative_score
  def initialize(params = {})
    if params.has_key? :genes
      @genotype = []
      params[:genes].each do |gen|
        if gen.class == Chromosome
          @genotype << gen
        elsif gen.class == Array
          @genotype << Chromosome.new({ vector_cells: gen})
        else
          raise ErrorCreateChromosome
        end
      end
    elsif (params.has_key?(:dad) && params.has_key?(:mom))
      @genotype = []
      9.times do |i|
        @genotype << Chromosome.new({dad: params[:dad][i], mom: params[:mom][i]})
      end
    else
      raise GenesInvalidos
    end
    @adaptation = params.fetch(:adaptation, 0.0)
    @score = params.fetch(:score, 0.0)
    @cumulative_score = params.fetch(:cumulative_score, 0.0)
    @elite = params.fetch(:elite, false)
  end

  def display
    i = 1
    puts  "_________________________"
    @genotype.each do |gene|
      puts "|       |       |       |"
      if (i%3) == 0
        gene.display
        puts  "|_______|_______|_______|"
      else
        gene.display
      end
      i += 1
    end
  end

  def fill_cells
    input = []
    @genotype.each do |gene|
      changes = [1,2,3,4,5,6,7,8,9]
      fijos = gene.find_fixed_nums
      fijos.each do |n|
        changes.delete_at(changes.index(n[:value]))
      end
      i = 0
      changes.shuffle.each do |n|
        while gene[i].fixed do
          i += 1
        end
        gene.set_value(n, i)
        i += 1
      end
    end
  end

  def get_genotype
    return @genotype
  end

  def mutate
    if rand < ODDS_MUTATION
      # XXX
      # Whenever dice are thrown, this piece of code doesn't check if the first
      # random value is in the middle of the chromosome, so if this value is
      # obtained, by switching the middle gene of two chromosome
      chromosome = rand(0..8)
      k1 = true
      k2 = true
      until k1==false
        i1 = rand(0..8)
        k1 = @genotype[chromosome][i1].fixed
        v1 = @genotype[chromosome][i1].value
      end
      until k2==false
        i2 = rand(0..8)
        k2 = @genotype[chromosome][i2].fixed
        v2 = @genotype[chromosome][i2].value
      end
      @genotype[chromosome].set_value(v1, i2)
      @genotype[chromosome].set_value(v2, i1)
    end
  end

  def calculate_weighted_adaptation#calcular_adaptacion_ponderada
    #
    # Calculate column scores
    #
    # Restriction Sums RS
    rsCuad =         [45, 45, 45, 45, 45, 45, 45, 45, 45]
    rpCuad =         [1, 1, 1, 1, 1, 1, 1, 1, 1]
    reaCuad =        [(1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a
    ]
    rsColumna =         [45, 45, 45, 45, 45, 45, 45, 45, 45]
    rpColumna =         [1, 1, 1, 1, 1, 1, 1, 1, 1]
    reaColumna =        [(1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a,
                         (1..9).to_a
    ]
    9.times do |i|
      9.times do |j|
        cell_value = @genotype[j][i].value

        rsColumna[i] -= cell_value
        rpColumna[i] = rpColumna[i] * cell_value
        reaColumna[i].delete_at(reaColumna[i].index(cell_value)) unless reaColumna[i].index(cell_value).nil?

        if (i < 3)
          if (j < 3)
            rsCuad[0] = rsCuad[0] - cell_value
            rpCuad[0] = rpCuad[0] * cell_value
            reaCuad[0].delete_at(reaCuad[0].index(cell_value)) unless reaCuad[0].index(cell_value).nil?
          elsif (j < 6)
            rsCuad[1] = rsCuad[1] - cell_value
            rpCuad[1] = rpCuad[1] * cell_value
            reaCuad[1].delete_at(reaCuad[1].index(cell_value)) unless reaCuad[1].index(cell_value).nil?
          elsif (j < 9)
            rsCuad[2] = rsCuad[2] - cell_value
            rpCuad[2] = rpCuad[2] * cell_value
            reaCuad[2].delete_at(reaCuad[2].index(cell_value)) unless reaCuad[2].index(cell_value).nil?
          end
        elsif (i < 6)
          if (j < 3)
            rsCuad[3] = rsCuad[3] - cell_value
            rpCuad[3] = rpCuad[3] * cell_value
            reaCuad[3].delete_at(reaCuad[3].index(cell_value)) unless reaCuad[3].index(cell_value).nil?
          elsif (j < 6)
            rsCuad[4] = rsCuad[4] - cell_value
            rpCuad[4] = rpCuad[4] * cell_value
            reaCuad[4].delete_at(reaCuad[4].index(cell_value)) unless reaCuad[4].index(cell_value).nil?
          elsif (j < 9)
            rsCuad[5] = rsCuad[5] - cell_value
            rpCuad[5] = rpCuad[5] * cell_value
            reaCuad[5].delete_at(reaCuad[5].index(cell_value)) unless reaCuad[5].index(cell_value).nil?
          end
        elsif (i < 9)
          if (j < 3)
            rsCuad[6] = rsCuad[6] - cell_value
            rpCuad[6] = rpCuad[6] * cell_value
            reaCuad[6].delete_at(reaCuad[6].index(cell_value)) unless reaCuad[6].index(cell_value).nil?
          elsif (j < 6)
            rsCuad[7] = rsCuad[7] - cell_value
            rpCuad[7] = rpCuad[7] * cell_value
            reaCuad[7].delete_at(reaCuad[7].index(cell_value)) unless reaCuad[7].index(cell_value).nil?
          elsif (j < 9)
            rsCuad[8] = rsCuad[8] - cell_value
            rpCuad[8] = rpCuad[8] * cell_value
            reaCuad[8].delete_at(reaCuad[8].index(cell_value)) unless reaCuad[8].index(cell_value).nil?
          end
        end

      end
      rpColumna[i] = (362880 - rpColumna[i]).abs
      rsColumna[i] = rsColumna[i].abs
    end
    9.times do |i|
      rsCuad[i] = rsCuad[i].abs
      rpCuad[i] = (362880 - rpCuad[i]).abs
    end
    rea = 0
    9.times do |i|
      rea += reaCuad[i].inject(:+) unless reaCuad[i].empty?
      rea += reaColumna[i].inject(:+) unless reaColumna[i].empty?
    end
    rs = rsCuad.inject(:+) + rsColumna.inject(:+)
    rp = rpCuad.inject(:+) + rpColumna.inject(:+)

    # According the book, the following parameters appearing in the formula are
    # the best ones according to experimental data
    @adaptation = ((5*rs) + rp + (20*rea)).to_f
    return @adaptation
  end

  def set_score(total)
    @score = (@adaptation.to_f/total)
  end

  def set_cumulative_score(amount)
    @cumulative_score = amount + @score
    return @cumulative_score
  end

end

class Population
  def initialize(_individuals)
    @individuals = []
    _individuals.each do |individual|
      if individual.class == Individual
        @individuals << individual
      else
        raise ErrorCreateIndividual
      end
    end
  end
end

if __FILE__ == $0

  puts "Cell"
  @cas_1 = Cell.new(0, false)
  @cas_2 = Cell.new(0, false)
  @cas_3 = Cell.new(4, true)

  @gen_1 = Chromosome.new({ vector_cells: [@cas_1, @cas_2, @cas_3]})
  @gen_2 = Chromosome.new({ vector_cells: [@cas_3, @cas_2, @cas_1]})
  @gen_3 = Chromosome.new({ vector_cells: [@cas_2, @cas_3, @cas_1]})


  puts "Genes"
  indiv1 = Individual.new({genes: [@gen_1, @gen_2, @gen_3], adaptation: 2.3, score: 5.0, cumulative_score: 3.0, elite: true})
  indiv2 = Individual.new({genes: [@gen_3, @gen_2, @gen_1]})

  indiv1.display
end


