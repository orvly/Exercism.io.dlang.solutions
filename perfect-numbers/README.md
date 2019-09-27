# Perfect Numbers

Determine if a number is perfect, abundant, or deficient based on
Nicomachus' (60 - 120 CE) classification scheme for natural numbers.

The Greek mathematician [Nicomachus](https://en.wikipedia.org/wiki/Nicomachus) devised a classification scheme for natural numbers, identifying each as belonging uniquely to the categories of **perfect**, **abundant**, or **deficient** based on their [aliquot sum](https://en.wikipedia.org/wiki/Aliquot_sum). The aliquot sum is defined as the sum of the factors of a number not including the number itself. For example, the aliquot sum of 15 is (1 + 3 + 5) = 9

- **Perfect**: aliquot sum = number
  - 6 is a perfect number because (1 + 2 + 3) = 6
  - 28 is a perfect number because (1 + 2 + 4 + 7 + 14) = 28
- **Abundant**: aliquot sum > number
  - 12 is an abundant number because (1 + 2 + 3 + 4 + 6) = 16
  - 24 is an abundant number because (1 + 2 + 3 + 4 + 6 + 8 + 12) = 36
- **Deficient**: aliquot sum < number
  - 8 is a deficient number because (1 + 2 + 4) = 7
  - Prime numbers are deficient

Implement a way to determine whether a given number is **perfect**. Depending on your language track, you may also need to implement a way to determine whether a given number is **abundant** or **deficient**.

Notes on my solution
====================
Instead of using the naive method of finding prime factors, I've read about factorizations methods a bit, and decided to use Pollard's rho method, which is a semi-probabilistic method of factoring an integer, which implementation is fairly simple.

But I've had various problems with this, including:

* Assuming at first that I could find all factors only using with Pollard's rho (for which it's totally inadequate), and then thinking I could find some factors with it. At the end I settled on finding a single factor.

* I had assumed this factor would always be prime, but it isn't necessarily, so I wrote an algorithm that given this initial factor, finds the rest of the prime factors of the original number.

* Given all those prime factors, I was still stumped as to how to find all factors. I finally understood that the correct way is building a power set from the set of prime factors, and then taking the product of each sub-set of the power set.

* As an exercise, I took the Haskell implementation of a power set from the Rosetta Code page of this algorithm, and translated it to D.  Implementing foldr was difficult since the Haskell version doesn't explicitly state that the types of the seed and the range are different, and I was confused by the D compiler errors at first until I finally grasped this and changed foldr to have 2 template parameters, which was very obvious in hindsight...

* I found the built-in assert lacking, specifically it only shows the line number, not what assert failed. I settled on using the dshould package which displays assert failures in a much nicer way.  However I've kept the original unit tests code using the regular assert, as to not force anyone who uses this code to use dshould.
