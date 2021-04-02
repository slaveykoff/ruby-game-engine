#!/usr/bin/env ruby

require_relative '../src/Utils.rb'


def test_sort()
	array = []
	10.times do
		array << rand(10)
	end
	puts "UNSORTED: #{array}"
	array = Utils::bubble_sort(array, lambda{|a,b|
		return a < b
	})
	puts "SORTED: #{array}"
end

def test_unique()
	array = []
	10.times do
		array << rand(5)
	end
	array = Utils::bubble_sort(array, lambda{|a,b|
		return a < b
	})
	puts "NON_UNIQUE: #{array}"
	
	array = Utils.unique(array, lambda{|a,b|
		return a == b
	})
	
	puts "UNIQUE: #{array}"
end

def test_queue()
	q = Utils::Queue.new()
	10.times do |i|
		q.enqueue(i)
		puts q
	end
	puts q
	puts "PEEK: #{q.peek()}"
	10.times do |i|
		puts q.take()
	end
	puts q
	puts q.empty?()
	q.clear()
	puts q.size()
end

def test_stack()
	
	s = Utils::Stack.new(10)
	10.times do |i|
		s.push(i)
		puts s
	end
	puts s
	puts "PEEK: #{s.peek()}"
	10.times do |i|
		puts s
		puts s.pop()
		puts s
	end
	throw "Must be empty!" if !s.empty?()
	puts s
	s.clear()
	puts s.size()
	
end

def main()
	test_sort()
	puts "==================="
	test_unique()
	puts "==================="
	test_queue()
	puts "==================="
	test_stack()
end

main()
