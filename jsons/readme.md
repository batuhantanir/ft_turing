# usage

## unary addition

#### 3 + 2 = 5 işlemini yapar
./ft_turing jsons/unary_add.json "111+11="

## palindrome

### Palindrom olan bir kelime (sonuç: 'y')
./ft_turing jsons/palindrome.json "ababa"

### Palindrom olmayan bir kelime (sonuç: 'n')
./ft_turing jsons/palindrome.json "hello"

## 0n1n

### 0n1n (sonuç: 'y')
./ft_turing jsons/0n1n.json "000111"

### (sonuç: 'n')
./ft_turing jsons/0n1n.json "00111"

### (sonuç: 'n')
./ft_turing jsons/0n1n.json "0101"

## 02n

#  (4 tane sıfır, sonuç: 'y')
./ft_turing jsons/even_zeros.json "0000"

#  (3 tane sıfır, sonuç: 'n')
./ft_turing jsons/even_zeros.json "000"