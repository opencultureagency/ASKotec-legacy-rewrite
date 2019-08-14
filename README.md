# #ASKotec - legacy rewrite scripts and assets

These scripts and assets can be used to rewrite the [#ASKotec-legacy repo](
https://github.com/opencultureagency/ASKotec-legacy).
The output is a much leaner, more git friendly version of the history:

* much less binaries
* down from ~ 500MB to ~ 500KB

You may check-out the results at the [new #ASKotec repo](
https://github.com/opencultureagency/ASKotec).

To run the conversion yourself on a Linux system
(tested on Debian testing as of August 2019),
simply run this in your terminal:

```bash
git clone https://github.com/opencultureagency/ASKotec-legacy-rewrite.git
cd ASKotec-legacy-rewrite
./filter-askotec
```

