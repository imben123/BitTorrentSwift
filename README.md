# BitTorrentSwift
A Swift implementation of the BitTorrent protocol, with very simple example iOS app.

## Introduction
This is a working implementation of the basic BitTorrent protocol. Still a work in progress with many features/optimisations/fixes needed, 
but for now it works! 🎉

I decided to write this because I found it a interesting a challenging way to practise my iOS, it was a lot of fun to write, 
and to demonstrate my ability to write good code!

### What can it do today?
- It can download a torrent from other seeds/peers given a valid `.torrent` file.
- It will also seed (upload) to other peers which connect.

### What is being worked on at the moment?
- Implementation of the DHT protocol (to enable trackerless torrents, and the ability to start a torrent via a magnet link)
- Dropping non-responsive and redundant peers
- Implementing an algorithm to speed up downloading the last bits.

### Things for future
- Make a nice app with a more useful UI as the example app
- Replace the socket library for one written in pure Swift to make this a pure swift codebase
