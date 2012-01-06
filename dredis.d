#!/usr/bin/rdmd --shebang -I/usr/include/d/hiredis -L-lhiredis
import core.sys.posix.sys.time;
import std.stdio;
import std.conv;
import std.string;
import hiredis;

struct RedisReply {
  string str;
}

class Redis {
  private redisContext* context;

  public void connect(const(char*) host, int ip, int timeout) {
    timeval ts = {1, timeout * 1000};
    context = redisConnectWithTimeout(host, ip, ts);
  }

  /****************************
   * String Operations
   ***************************/

  public bool set(const(char)[] key, const(char)[] val) {
    return boolCmd("SET", key, val);
  }

  public string get(const(char)[] key) {
    redisReply* rep = cast(redisReply*) redisCommand(context, "GET %s", toStringz(key));
    string s = to!string(rep.str);
    freeReplyObject(rep);
    return to!string(s);
  }

  public bool del(const(char)[] key) {
    return boolCmd("DEL", key);
  }

  private bool boolCmd(string cmd, const(char)[] key, const(char)[] val = "") {
    redisReply* rep = cast(redisReply*) redisCommand(context, toStringz(cmd ~ " %s %s"), toStringz(key), toStringz(val));
    freeReplyObject(rep);
    // TODO: check whether successfull
    return true;
  }
}

void main() {
  auto r = new Redis();
  r.connect("127.0.0.1", 6379, 5000);
  writeln(r.get("foo"));
  r.set("haha", "hooho");
  writeln(r.get("haha"));
  r.del("haha");
  writeln(r.get("mylist"));
}
