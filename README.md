# Security-Conscious Hardware

Our paper will be published at the *25th IEEE Latin American Test Symposium 2024 (LATS'24)*.

This is a collection of experiments with the goal of making variable-time hardware accelerators secure, but also as performant as possible.
The basic idea is that these designs dynamically adjust their latency based on the confidentiality level of their operands.
In essence, performance optimizations are allowed, as long as the only depend on public operands.
This ensures that the desings are data-oblivious, but leaves room for optimization if operands with mixed confidentiality levels are used.

This repository contains the original designs and their security-conscious version along with a formal verification framework.
