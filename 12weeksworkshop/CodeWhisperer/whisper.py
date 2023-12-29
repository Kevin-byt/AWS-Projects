# //create a function that takes in a string and returns the number of vowels in the string

def count_vowels(string):
    count = 0
    for char in string:
        if char in "aeiouAEIOU":
            count += 1
    return count

# //run the function

string = input("Enter a string: ")

vowel_count = count_vowels(string)

print("The number of vowels in the string is:", vowel_count)

