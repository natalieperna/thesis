\chapter{Related Work}
\label{cha:related_work}

In this chapter, we provide a survey of the literature and discuss some existing techniques for improving functional code that relate closely to our work.

\section{Common subexpression elimination}

Common subexpression elimination (CSE) is a compiler optimisation that reduces execution time by avoid repeated computations of the same expression \citep{Chitil-1998}. This very similar to our goal with case squashing. As anyone familiar with the nature of purely functional programming languages might realise, identification of common subexpressions is much simpler in a functional language thanks to the expectation of referential transparency \citep{Chitil-1998}. (As a reminder, referential transparency means that an expression always produces the same result regardless of the context in which it is evaluated.)

\citet{appel1992} first implemented CSE in the strict functional language ML's compiler, and \citet{Chitil-1998} first explored the implementation of CSE in a lazy functional language, Haskell. The difficulty with implementing CSE in a lazy language is that, although common subexpressions are easy to identify, determining which common subexpressions will yield a benefit by being eliminated is more challenging. To avoid complex data flow analysis on functional code, \citet{Chitil-1998} developed some simple syntactic conditions for judging when CSE is beneficial in Haskell code. We omit these from our survey, as such heuristics are unnecessary for our optimisation. We instead focus on the relevant ``compilation by transformation'' approach used when implementing CSE in GHC.

The GHC compilation process consists of translating Haskell code into a second-order $\lambda$-calculus language called Core, at which point a series of optimising transformation are performed, and the backend code generator transforms Core code into the final output \citep{Chitil-1998}. This process is very similar to the Agda compilation process, which translates Agda code into Treeless code, applies a series of optimising transformations, and finally generates Haskell code through the backend, as discussed in Section~\ref{sec:background_agda}.

The syntax of the Core intermediate language of Haskell is very similar to Treeless, with expressions consisting mainly of $\lambda$ abstractions, |let| bindings, |case| expressions, constructors, literals and function applications, much like Agda's Treeless syntax outlined in Figure~\ref{code:TTerm}.

CSE is implemented in GHC with a single recursive traversal of the Core program. For each expression, its subexpressions are first transformed, then it is determined whether the whole transformed expression has occurred already \citep{Chitil-1998}. An example of this is shown in Figure~\ref{code:cse_haskell}.

\begin{figure}[h]
Given the expression:

|let x = 3 in let y = 2+3 in 2+3+4|

the first CSE on the subexpressions yields:

|let x = 3 in let y = 2+x in y+4|

and then the recursive transformation produces:

|let x = 3 in let y = 2+x in 2+x+4|

\caption{Common subexpression elimination transformation in Haskell \citep{Chitil-1998}.}
\label{code:cse_haskell}
\end{figure}

\section{Let-floating}
\label{sec:let_floating}

\citet{jones1996}'s ``Let-floating: moving bindings to give faster programs'' discusses the effects of a group of compiler optimisations for Haskell which move let bindings to reduce heap allocation and execution time. The cumulative impact of their efforts to move let-bindings around in Haskell code resulted in more than a 30\% reduction in heap allocation and a 15\% reduction in execution time.

\citet{jones1996} explain that GHC (the Glasgow Haskell Compiler) is an optimising compiler whose guiding principle is \textit{compilation by transformation}. Whenever possible, optimisations in GHC are implemented as correctness-preserving program transformations, a principle that is reflected in the Agda compiler as well. Most of our optimisations that we present later in this thesis are also best thought of as ``correctness-preserving program transformations''.

Before we approach the optimisations presented by \citet{jones1996} we discuss the operational interpretation of the Haskell Core language. Haskell Core expressions are built from the syntax shown in Figure~\ref{fig:haskell_core}.

\input{Figures/HaskellCore}

In order to best understand the advantages of the let-floating transformations described below, there are two facts about the operational semantics of Core that are useful to know:
\begin{enumerate}
\item |let| bindings, and only |let| bindings, perform heap allocation.
\item |case| expressions, and only |case| expressions, perform evaluation.
\end{enumerate}

In this paper, three types of let-floating transformations are presented:
\begin{enumerate}
\item ``Floating inwards'' to move bindings as far inwards as possible,
\item ``The full laziness transformation'' which floats some bindings outside enclosing lambda abstractions, and
\item ``Local transformations'' which move bindings a several optimising ways \citep{jones1996}.
\end{enumerate}

\subsection*{Floating inwards}

Floating inwards is an straightforward optimisation that aims to move all let bindings as far inward in the expression tree as possible. This accomplishes three separate benefits:
\begin{itemize}
\item It increases the chance that a binding will not be met in program execution, if it is not needed on a particular branch.
\item It increases the chance that strictness analysis will be able to perform further optimisations.
\item It makes it possible for further redundant expressions to be eliminated \citep{jones1996}.
\end{itemize}

Consider as an example, the Haskell code:
\begin{code}
  let x = case y of (a,b) -> a
  in
  case y of
    (p,q) -> x+p
\end{code}

and its optimised version with let-bindings floated inward:
\begin{code}
  case y of
    (p,q) -> let x = case y of (a,b) -> a
             in x+p
\end{code}

These two Haskell expressions are semantically-equivalent, but the second has potential to become more efficient than the first because later optimisations will be able to identify the opportunity to remove the redundant inner case expression which scrutinises the same variable as the outer case expression \citep{jones1996}. Though it wasn't clear in the first expression, because the case expressions weren't nested, the second expression can now benefit from a GHC optimisation much like our ``case squashing'' optimisation.

\subsection*{Full laziness}

While the above transformation attempts to push bindings inwards, the full laziness transformation does the reverse, floating bindings outwards. By floating some bindings out of lambda abstractions, we can avoid re-computing the same expression on repeated recursive calls to the same function \citep{jones1996}.

The benefit from this increased sharing outweighs the detriment of increasing the let scope in most cases where:
\begin{itemize}
\item the expression being bound requires a non-negligible amount of computational work to evaluate; and
\item the lambda abstraction it is used in is called more than once \citep{jones1996}.
\end{itemize}

Consider as an example, the Haskell code\citep{jones1996}:
\begin{code}
  f = \ xs ->
    let g = \ y -> let n = length xs
                  in ...g...n...
    in ...g...
\end{code}

and its optimised version with let-bindings floated outward:
\begin{code}
  f = \ xs ->
    let n = length xs
    in let g = \ y -> ...g...n...
       in ...g...
\end{code}

In order to maximise the number of opportunities for this type of let-floating, it may be necessary to create dummy let bindings for free subexpressions in the lambda abstraction, so that they can be floated out as well \citep{jones1996}.

\subsection*{Local transformations}

The local transformations consist of a series of three small rewrite rules as follows:

\begin{enumerate}
\item |(let v = e in b) a| $\quad \to \quad$ |let v = e in b a|

Moving the let outside the application cannot have a negative effect, but it can have a positive effect by creating opportunities for other optimisations \citep{jones1996}.

Consider the case where |b| is a lambda function. Before floating the let outside the application, the function cannot be applied to |a|:

\edcomm{NP}{Change notation of <expr>s.}

\begin{code}
  (let v = <v-rhs> in (\ x -> ...x...)) a
\end{code}

However, after floating the let outside, it is clear that a beta-reduction rule can be applied, substituting an |a| for ever |x| at compile-time:

\begin{code}
  let v = <v-rhs> in (\ x -> ...x...) a
\end{code}

\item |case (let v = e in b) of alts| $\quad \to \quad$ |let v = e in case b of alts|

Likewise for moving the let outside a case expression, it won't have a negative effect, but could have a positive effect \citep{jones1996}.

Consider the case where |b| is a constructor application. Before floating the let outside the case expression, there isn't a clear correspondence between the constructor and the alternatives:

\begin{code}
  case (let v = <v-rhs> in con v1 v2 v3) of <alts>
\end{code}

However, after floating the let outside, it is clear that the case expression can be simplified to the body of the alternative with the same constructor, without any evaluation being performed:

\begin{code}
  let v = <v-rhs> in case con v1 v2 v3 of <alts>
\end{code}

\item |let x = let  v = e in b in c| $\quad \to \quad$ |let v = e in let x = b in c|

Moving a let binding from the right-hand side of another let binding to outside it can have several advantages including potentially reducing the need for some heap allocation when the final form of the second binding becomes more clear \citep{jones1996}.

In the following example, floating the let binding out reveals a head normal form. Without floating, when |x| was met in the |<body>|, we would evaluate |x| by computing the pair |(v,v)| and overwriting the heap-allocated thunk for |x| with the result:

\begin{code}
  let x = let v = <v-rhs> in (v,v)
  in <body>
\end{code}

With floating, we would instead allocate a thunk for |v| and a pair for |x|, so that |x| is allocated in its final form:

\begin{code}
  let v = <v-rhs>
  in let x = (v,v)
     in <body>
\end{code}

This means that when |x| is met in the |<body>| and evaluated, no update to the thunk would be needed, saving a significant amount of memory traffic \citep{jones1996}.

\end{enumerate}

Similar methods to these let-floating transformations are used in our patterned let-floating across function calls, with the same goal of increasing sharing and decreasing re-evaluation of the same expressions.

\section{Alternate method of case squashing}
\label{sub:alternate_case_squash}

Following development of @--squash-cases@, an optimisation was added to the Agda compiler's Simplify stage which accomplishes the same goals as @--squash-cases@ in a slightly different way. We examine here that method of removing repeated case expressions.

Immediately following the conversion of compiled clauses to treeless syntax in the Agda compiler, a series of optimising transformations are applied before the treeless expression is returned. One such step is the ``simplify'' group of transformations, which modify a |TTerm| in a variety of optimising ways.

As the expression is traversed, |simplify| is recursively called on each |TTerm| term, and |simpAlt| is called on each |TAlt| alternative. Given some expression casing on de Bruijn index $x$, for each alternative of the pattern |TACon name arity body|, the scrutinised variable index in the body, $x + arity$, is looked up in the variable environment. If the variable has already been bound, and therefore has a different de Bruijn index, $y$, a rewrite rule is added to the constructor. The rewrite rule indicates that every instance of |TApp (TCon name) (TVar i || i <- [arity-1,arity-2..0])| in the alternative's body should be replaced with a |TVar y|.

The rewrite rule is encoded as part of the wrapper |Reader| environment that is carried along with the |TTerm| throughout simplification, and is evaluated later by applying substitutions. It is at this point that all necessary de Bruijn index shifting is managed.

An abridged version of @Treeless/Simplify.hs@ showing the primary functions involved in this optimisation in the updated Agda compiler is available in Appendix~\ref{app:simplify}.