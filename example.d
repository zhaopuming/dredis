#!/usr/bin/rdmd -I/usr/include/d/hiredis -L-lhiredis
import std.stdio;
import core.stdc.stdlib;
import core.sys.posix.sys.time;
import std.conv;

import dredis;

void main() {
  auto r = new Dredis();
  bool succ = r.connect("127.0.0.1", 6379, 5000);
  if (!succ)
  {
    writeln("Cannot connect to redis!!!");
    return;
  }
  writeln(r.get("foo"));
  r.set("haha", "hooho");
  writeln(r.get("haha"));
  r.del("haha");
  writeln(r.get("noexist"));
  writeln(r.get("mylist"));
  writeln(r.getLong("a"));
}
