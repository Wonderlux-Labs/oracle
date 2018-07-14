require 'marky_markov'
require 'pry'
require 'yaml'
require 'literate_randomizer'

class String
  def titlecase
    split(/([[:alpha:]]+)/).map(&:capitalize).join
  end
end

def setup
  @markov = MarkyMarkov::Dictionary.new("#{rand(10000)}asdf")
  # @markov.parse_file 'text/iching.txt'
  @markov.parse_file 'text/iching-words.txt'
  @markov.parse_file 'text/tarot-words.txt'
  @markov.parse_file 'text/mckenna.txt'
  @markov.parse_file 'text/rilke-words.txt'
  @markov.save_dictionary!

  @seeds_one = YAML.load(File.open('symbols/arcana.yml', 'r+'))
  @seeds_two = YAML.load(File.open('symbols/dreams.yml', 'r+'))
  @seeds_three = YAML.load(File.open('symbols/qualities.yml', 'r+'))
  @seeds_four = YAML.load(File.open('symbols/hexagrams.yml', 'r+'))

  @random = LiterateRandomizer.create(source_material_file: "#{Dir.pwd}/text/tarot-words.txt")

  @counter = 0
end

def get_seed_word
  words = [@seeds_one, @seeds_two, @seeds_three, @seeds_four].sample
  words.sample
end

def find_sentence_for_word
  1000.times do
    sentence = @markov.generate_n_sentences(rand(3))
    return sentence if sentence.downcase.include?(@seed_word.downcase)
  end
  nil
end

def find_sentence
   sentence = nil
   @seed_word = get_seed_word
   sentence = find_sentence_for_word
   return sentence if sentence
   @counter += 1
   return @random.sentence if @counter > 10
   find_sentence
 end

 def modifiers
   [
     'leads to',
     'follows',
     'perplexes',
     'shifts towards',
     'obstructs',
     'enhances',
     'brings about',
     'comes first, then',
     'is a possibility, but so is',
     'cannot stop',
     'can turn into',
     'can never stop',
     'seems likely, but so does',
     'can only lead to hesitation. Instead go for'
    ]
  end

setup

loop do
  gets.chomp
  sentence = find_sentence
  sentence = sentence.sub(/\w+/) { |m| m.capitalize }
  sentence = sentence.gsub(/#{Regexp.escape(@seed_word)}/i, @seed_word.titlecase)
  rand = rand(1..100)
  if rand <= 4
    puts "TYPE 1"
    puts "#{get_seed_word.titlecase} #{modifiers.sample} #{get_seed_word.downcase}."
  elsif rand <= 7
    puts "TYPE 2"
    sentence = sentence.split('.').first
    sentence = sentence.split(',').first if sentence.split(' ').length > 10
    puts "#{sentence}."
  elsif rand <= 10
    puts "TYPE 3"
    puts "(#{get_seed_word.titlecase}) #{sentence.split('.').first}."
  else
    puts sentence.gsub(/#{Regexp.escape(@seed_word)}/i, @seed_word.upcase)
  end
end
