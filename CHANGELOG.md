## 0.0.1

* Release the first version, support v1, v1.1, v2.2, v2.3, v2.4 ID3 tag parsing.

## 0.0.3

* Fix the BUG when decoding.
* Support ID3V1, ID3V1.1 encoding.

## 0.0.5

* Fix the BUG when decoding.
* Support ID3V2.3 encoding, you can modify or add song name [title], artist [artist], album [album], cover image [picture], encoding format [encoding], and some user-defined information [userDefines].

## 0.0.6

* Fix the bug in ID3v2.3 encoding, which will cause the byte array to become larger and out of bounds.

## 0.0.7
* Fix `latin1` decoding problem. When there is 0x00 in the byte array, it will cause a decoding exception.
* Fix the problem that the array is out of bounds when decoding the ID3v1 `genre` field to the default 255.

## 0.0.8
* Export library named `id3_codec`.

## 0.0.9
* Optimize `getTagMap()` interface return data of `ID3MetataInfo`, limited to basic types. It is convenient for users to obtain values in the form of key-value pairs.

## 0.0.10
* [Important] Fix a serious bug on **v2.3**. The timing of this bug is: encode first, then decode, because the high byte of the frame size is 0 when calculating, and the way to calculate the frame size when decoding is that the high byte of the byte is 1. In the end, an invalid string appears, which is caused by the encoder being unable to encode 0x00.

## 1.0.0
* Improve documentation and comments.

## 1.0.1 & 1.0.2
* Specifies the naming of variables and classes. And added a litter comments.