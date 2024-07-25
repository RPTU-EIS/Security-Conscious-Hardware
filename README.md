# Security-Conscious Hardware

The corresponding paper to this repository was published at the *25th IEEE Latin American Test Symposium 2024 (LATS'24)*[^1].

This is a collection of experiments with the goal of making variable-time hardware accelerators secure, but also as performant as possible.
The basic idea is that these designs dynamically adjust their latency based on the confidentiality level of their operands.
In essence, performance optimizations are allowed, as long as the only depend on public operands.
This ensures that the desings are data-oblivious, but leaves room for optimization if operands with mixed confidentiality levels are used.

This repository contains the original designs and their security-conscious version along with a formal verification framework.

[^1]: L. Deutschmann, Y. Kazhalawi, J. Seckinger, A.L. Duque Antón, J. Müller, M.R. Fadiheh, D. Stoffel, and W.Kunz: 
[Data-Oblivious and Performant: On Designing Security-Conscious Hardware](https://ieeexplore.ieee.org/document/10534597)
2024 IEEE 25th Latin American Test Symposium (LATS), Maceio, Brazil, 2024, pp. 1-6, doi: 10.1109/LATS62223.2024.10534597. 
