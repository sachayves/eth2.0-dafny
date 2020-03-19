include "../utils/SeqHelpers.dfy"


/** Helper types.  */
module Helpers {

    import opened SeqHelpers

    /** Try type (as in Scala). */
    datatype Try<T> = Success(t : T) | Failure 

    /* Option type */
    datatype Option<T> = None | Some(T)

    /* Either type */
    datatype Either<T> = Left(T) | Right(T)

    /**
     *  Ceiling function.
     *
     *  @param  n   Numerator
     *  @param  d   Denominator
     *  @returns    The smallest integer last than float(n / d).
     */
    function method ceil(n: nat, d: nat) : nat
        requires d != 0
        ensures n >= 1 ==> ceil(n , d) >= 1
        ensures ceil(n ,d) == 0 <==> n == 0
    {
        if (n % d == 0) then 
            n / d
        else 
            n / d + 1
    }       

    /** Create Sequences with same element. 
     *
     *  @tparam T   A type.
     *  @param  t   An value.
     *  @param  k   A non-negative integer.
     *  @returns    A seq [t,t, ..., t] of size k.
     */
    function method timeSeq<T>(t : T, k : nat) : seq<T> 
        ensures |timeSeq(t,k)| == k
        decreases k
    {
        if k == 0 then []
        else [t] + timeSeq(t, k - 1)
    }

    //  Seq of Seqs functions.

    /** .
     *  Flatten seqs of seqs.
     *
     *  @tparam T   A type.
     *  @param  s   A sequence of sequences of T.
     *  @returns    The flattened sequence which is concatenation of the sequences of
     *              each element.
     *
     *  @example    flatten([]) = [], flatten [ [], [] ] = [], 
     *              flatten [ [1,2], [3]] = [1,2,3],
     *              flatten([], [1,2]) = [1,2].
     */
    function flatten<T>(s: seq<seq<T>>): seq<T>
        ensures |flatten(s)| == flattenLength(s)

        decreases  s
    {
        if |s| == 0 then []
        else s[0] + flatten(s[1..])
    }

    //  Properties of flatten

    /** 
     *  The set of elements in flatten is the same as in the union of the elements. 
     */
    lemma {:induction s} flattenPreservesElements<T>(s : seq<seq<T>>, x : T)
        ensures x in flatten(s) <==> exists i :: 0 <= i < |s| && x in s[i]
    {   //  Thanks Dafny.
    }

    /**
     *  Flatten dsitributes over append left/right element.
     *  This is a lemma used to prove the more general 
     *  distribution lemma `flattenDistributes`.
     */
    lemma {:induction s} flattenElimLast<T>(s: seq<seq<T>>, x : seq<T>)
        ensures flatten(s + [x]) == flatten(s) + x
        // ensures flatten([x] + s) == x + flatten(s)

        decreases s
    {
        if (|s| == 0) {
            //  Thanks Dafny
        } else {
            calc {
                flatten(s + [x]);
                == { seqHeadTail(s) ; } 
                flatten([s[0]] + s[1..] + [x]);
                == { seqConcatAssoc([s[0]], s[1..], [x]) ; }
                flatten([s[0]] + (s[1..] + [x]));
                == // Definition of flatten
                s[0] + flatten(s[1..] + [x]);
                == { flattenElimLast(s[1..], x); }
                s[0] + flatten(s[1..]) + x;
            }
        }
    }

    /** 
     * Length distributes over flatten of concatenations.
     */
    lemma {:induction s1, s2} lengthDistribFlatten<T>(s1: seq<seq<T>>, s2: seq<seq<T>>)
        ensures |flatten(s1 + s2)| == |flatten(s1)| + |flatten(s2)|
    {
        calc {
            |flatten(s1 + s2)|;
            == { flattenDistributes(s1, s2) ; }
            |flatten(s1) + flatten(s2)|;
            == //   length distributes over seq
            |flatten(s1)| + |flatten(s2)|;
        }
    }
    
    /**
     *  Flatten distributes.
     */
    lemma {:induction s2} flattenDistributes<T>(s1: seq<seq<T>>, s2: seq<seq<T>>)
        ensures flatten(s1 + s2) == flatten(s1) + flatten(s2)
        decreases |s2|
    {   
        if (|s2| == 0) {
            calc {
                flatten(s1 + s2);
                == { seqElimEmpty(s1) ; }
                flatten(s1) ;
            }
        } else {
            calc {
                flatten(s1 + s2);
                == { seqHeadTail(s2) ; }
                flatten(s1 + ([s2[0]] + s2[1..]));
                == { seqConcatAssoc(s1, [s2[0]], s2[1..]) ; }
                flatten((s1 + [s2[0]]) + s2[1..]);
                == { flattenDistributes(s1 + [s2[0]], s2[1..]) ;}
                flatten(s1 + [s2[0]]) + flatten(s2[1..]);
                == {  flattenElimLast(s1, s2[0]) ;}
                (flatten(s1) + s2[0]) + flatten(s2[1..]);
            }
        }
    }

    //  Length of flattened sequences.
    
    /** 
     *  Lenght of a flattened sequence.
     *  
     *  @tparam T   A type.
     *  @param  s   A sequence of sequences of T.
     *  @returns    The sum of the lengths of the subsequences.
     */
    function flattenLength<T>(s : seq<seq<T>>) : nat 
        ensures flattenLength(s) >= 0 
        decreases s
    {
        if s == [] then 0
        else |s[0]| + flattenLength(s[1..])
    }

     //  flattenLength properties.

    lemma {:induction s} flattenLengthCommutes<T>(s: seq<seq<T>>, x : seq<T>)
        ensures flattenLength(s + [x]) == flattenLength([x] + s)
    {   
        calc {
            flattenLength(s + [x]) ;
            ==
            |flatten(s + [x])| ;
            == { flattenElimLast(s, x) ;}
            |flatten(s)| + |x|;
        }
    }

    lemma {:induction s} lem5<T>(s : seq<seq<T>>, i:nat, j : nat)
        requires 0 <= i < |s| - 1
        requires 0 <= j < |s[i]|
        ensures flattenLength(s[..i]) + j < flattenLength(s[..i + 1])
        ensures flattenLength(s[..i]) + j < flattenLength(s)
        ensures flattenLength(s[..i]) + j < |flatten(s)|
    {   
       calc {
            flattenLength(s[..i]) + j ;
            <
            flattenLength(s[..i]) + |s[i]| ;
            == { flattenLenghtElim(s[..i], s[i]); }
            flattenLength(s[..i] + [s[i]]);
            == { seqInitLast(s, i) ; }
            flattenLength(s[..i + 1]);
       }
       calc {
           flattenLength(s[..i]) + j ;
           <
           flattenLength(s[..i + 1]) ;
           <= { flattenLengthMonotonic(s, i + 1) ; }
           flattenLength(s);
       }
    } 
    
    lemma {:induction s} flattenLenghtElim<T>(s: seq<seq<T>>, x : seq<T>) 
        ensures flattenLength(s + [x]) == flattenLength(s) + |x|
        ensures flattenLength([x] + s) == flattenLength(s) + |x|
    {   
        calc {
            flattenLength(s + [x]);
            == { flattenLengthCommutes(s, x); }
            flattenLength([x] + s);        
        }
    }

    lemma flattenLengthDistributes<T>(s1: seq<seq<T>>, s2: seq<seq<T>>)
        ensures flattenLength(s1 + s2) == flattenLength(s1) + flattenLength(s2)
    {
        calc {
            flattenLength(s1 + s2);
            ==
            |flatten(s1 + s2)|;
            == { flattenDistributes(s1, s2); }
            |flatten(s1)| +  |flatten(s2)|;
            == 
            flattenLength(s1) + flattenLength(s2);
        }
    }

    lemma flattenLengthMonotonic<T>(s: seq<seq<T>>, i : nat)
        requires 0 <= i < |s|
        ensures flattenLength(s[..i]) <= flattenLength(s)
    {
        calc {
            flattenLength(s);
            == { seqSplit(s, i) ; }
            flattenLength(s[..i] + s[i..]);
            ==
            |flatten(s[..i] + s[i..])|;
            == { lengthDistribFlatten(s[..i], s[i..]) ; }
            |flatten(s[..i])| + |flatten(s[i..])|;
        }
    }

    lemma foo1<T>(s: seq<seq<T>>, i : nat, j : nat)
        requires 0 <= i <= j < |s|
        ensures flattenLength(s[..i]) <= flattenLength(s[..j])
    {
        calc >= {
            flattenLength(s[..j]);
            == calc {
                 s[..j] ;
                 ==
                 s[..i] + s[i..j];
            }
            flattenLength(s[..i] + s[i..j]);
            == { flattenLengthDistributes(s[..i], s[i..j]) ; }
            flattenLength(s[..i]) +  flattenLength(s[i..j]);
        }
    }

//     lemma foo13<T>(s : seq<seq<T>>, i:nat, j : nat)
//         requires 0 <= i < |s| - 1
//         requires 0 <= j < |s[i]|
//         requires flattenLength(s[..i]) + j < |flatten(s)|
//         ensures flatten(s)[flattenLength(s[..i]) + j] == s[i][j]
//         {
//         }        
//    }

}
