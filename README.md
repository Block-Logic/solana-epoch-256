# solana-epoch-256
Scripts and Data Related to Solana Epoch 256.

I am looking for correlations between cluster throughput and skipped slots.
This repository contains some script and data files. If have data, scripts,
charts, or anything else to contribute, contact Brian Long for write
permissions.

- solana-block-production.rb -- a quick script to create a CSV file with skipped slot data.
- solana-block-transaction.rb -- a script to pull block data from RPC, count the number of transactions, and create a CSV file.
- solana-epoch-256.xls -- an Excel spreadsheet to get a quick look at some data.

This entire repo is work-in-process. Please help if you can!

## Interesting Blocks
These blocks by the same leader had approximately the same number of compute units, but the transaction quantity is vastly different.
- 110592744 with 584 program invokes + 981 votes and 3,343,119 compute units by private validator (4oSR)
- 110592745 with 606 program invokes + 22 votes and 6,180,410 compute units by private validator (4oSR)
- 110592746 with 751 program invokes + 980 votes and 7,114,667 compute units by private validator (4oSR)
- 110592747 with 734 program invokes + 445 votes and 5,413,485 compute units by private validator (4oSR)
