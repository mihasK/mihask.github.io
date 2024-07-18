---
layout: post
title:  "The right way to jsonify vector embeddings"
date:   2023-06-13 15:36:21 +0300
categories: python
---
AI projects written in Python often involve working with numpy arrays. Even if you don’t train your own neural network, you’ll at least be touching vector embeddings, either to support semantic search or make an LLM agent empowered with RAG. Sometimes you need to serialize them in JSON, and the standard library is not the best option for this task.

# TL;DR
* The standard json module is slow
* Also, data type could be unnoticeably lost (float32 => float64)
* There are fast third-party libraries, such as orjson; it handles numpy directly
* In some cases you’re restricted to using the standard library interface; thankfully, it’s easy to override
* Writing vector embeddings into Redis is a good example of orjson application: a large fraction of processing time is JSON conversion
* A full code of example can be found here

# Disclaimer:
*All examples here were tested in a specific environment (laptop with M1 processor, Redis database was run locally via docker container restricted to 1 core CPU), and results do not pretend to be considered as an objective benchmark. In the case of real-world production usage, more significant losses usually occur on communication with a remote Redis server, as well as on other operations discussed in this post, such as generating embeddings. So a reader should estimate the advantages in their exact case before beginning to implement this optimization. Although in this case, it costs almost nothing (just install a package from pypi and override some code), premature optimization is “still the root of all evils”.*


# ...

It’s no secret that the standard json module in Python is quite slow. Although they do use C extensions for it, it seems they never set a goal to make it as fast as possible. All right, it’s simple and enough for the majority of cases; if somebody needs extremely optimized code, they can always write a library.

Let’s look at some use cases: you need to convert your text embeddings to JSON. Why would you do this? For example, you’re going to store it in Redis for later semantic search. Yes, Redis supports cosine similarity searches and could serve you as a vector database!

In the following examples, we will use OpenAI’s size of embeddings — 1536. Well, if you really get them from OpenAI API, they would already come to you in JSON format, and you don’t need to convert them. But suppose you received them from your locally run transformer model, so they are stored in numpy arrays.

Let’s look into the performance of the naive approach: convert numpy to python list (it’s quick), and then serialize the list. All examples from now on will be provided in the form of Jupyter cell execution.

![Image](/images/json-emb/1.webp)


Half a millisecond to jsonify! Should we care at all about such a tiny operation? Well, at first it’s on a fast M1 processor and could be noticeably slower on your server. But the second thing that just hurts my soul is why converting to string (this is what essentially happens) takes 30 times more than converting numpy to the list ? It's just crazy non-optimal code! In essence, this operation just requires allocation of memory and copying bytes, so good implementation should give execution time comparable to converting from numpy to list (i.e. more than 10 times quicker).

The next thing that's happening wrong: while you’re converting to a list, it converts float32 to float64 and **causes trouble with precision**:

![Image](/images/json-emb/2.webp)


Okay, there’s a library that does things right. Meet orjson!

Let’s see how it looks in case we use orjson. Right, it’s capable of serializing numpy directly. And not only that, other useful Python types are supported, or handled better than in the standard module — please look into its docs (I recall now that I often stump upon with serializing of UIDs when developing API, which is not handled by the standard library but supported by orjson out of the box).

![Image](/images/json-emb/3.webp)


One caveat with orjson — it produces bytes output instead of str . This is probably the right approach, but in case you have some compatibility issues and require output of type str , it’s easy to fix:

![Image](/images/json-emb/4.webp)

Sometimes you’re restricted from a third-party library (such an example with Redis will be given below) that enforces the use of a standard json module. Hopefully, the latter is designed to be easily overridden.

Here is a custom encoder that enables you to use orjson via the standard module interface:

![Image](/images/json-emb/5.webp)


One example of using such a custom encoder is storing json documents in Redis. Of course, in the AI era, you also store vector embeddings for later semantic search!

The Redis client library requires you to use the standard json module, but an encoder can be overridden.

Let’s first use a naive approach: converting numpy to a list, and then dumping a list via the standard module. Redis runs locally, so there are almost no communication costs, and the procedure is relatively quick.

![Image](/images/json-emb/6.webp)

And let’s compare this now with fast serialization. Let’s even skip the difficulties with precision — we will use float64 in both cases.

![Image](/images/json-emb/7.webp)

Wow, 4 times faster! It means that you lose 3/4 of the time just on inefficient JSON-serialization of embeddings. A surprising result, and nice work, orjson!

Whether it saves much or not, depends on your application. Probably not significant in the majority of cases. However, if you ever encounter issues with the slowness of Python’s json, you’ll know what to do!

P.S.

— Full code with examples can be found in [this jupyter notebook][jup-code].



[jup-code]: https://nbviewer.org/github/mihasK/try-vector-search-on-common-db/blob/main/best_way_to_jsonify_numpy.ipynb
