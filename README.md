# Civil Networks Anti Cheat

## What is this?
This is the source code to Civil Networks's Anti-Cheat, dating 2nd February 2024.

## Why was this published?
Let's get something out of the way first of all, I am a (very) old CN player, with my roots dating back to 2016. 

I offered to help counter their cheating problem, I was offered pay to create an Anti-Cheat solution.  

[Ventz](https://steamcommunity.com/id/ventz1/) later used every excuse under the sun to get rid of me and to avoid paying me, included but not limited to [libellous pedophilia claims](https://i.imgur.com/pWGngSS.png) (based on his [own personal trauma](https://i.imgur.com/og3aaed.png)), and bug abuse claims.  

He then later resulted to [threatening legal action](https://i.imgur.com/h5X8naI.png).  

## What does this include?
An implementation of a well-known method of detecting script execution known as an **environment grab**, and some spicy inner workings of CN server stuff.

Garry's Mod gives servers much more control over the client than what other games like Roblox do, allowing you to set a metatable on large globals like "net", hoping that exploiter scripts will use it, and allow you to getfenv() to determine if their environment is from a cheat.
