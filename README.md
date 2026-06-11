# Arandu
## A Naive DNN 32b Accelerator using Double Circular Linked Buffers and Latency Hiding

This project is not an attempt to inovate the well-established DNN hardware architecture fiel. It is just a personal project I made concurrently with my studies, including loop nesting, data reuse, etc. and trying to use minimal digital resources like flip-flops and combinational logic.

One of the key ideas in this module is the input/activation buffers, which are inspired in a memory element called Doubly Circular Linked Lists (DCLL). Using this kind of storage, it becomes possible to reuse each element of the vectors (to and from the matrix/vector multiplication) without addressing, since the elements of the buffers only share data with your neighbors. The weights are stored in a on-chip memory, and they must be stored with some considerations arising from this method.

It is believed (personaly) that this approach can get advantages on managing the control signals and routing the dataflow. On the other hand, the buffer will certanly show more switching activity and thus consuming more energy then its addressed version. When the module is capable of performing an inference from a trained model, synthesis data will be collected using Genus from Cadence to confirm the assumptions.

<img width="892" height="782" alt="Captura de tela de 2026-06-11 12-09-32" src="https://github.com/user-attachments/assets/f3f30da6-edf9-4c25-acfd-b4bd0b7baad4" />

