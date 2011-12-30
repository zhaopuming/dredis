#!/usr/bin/rdmd -L-lhiredis
import std.stdio;
import core.stdc.stdlib;
import dredis;
import core.sys.posix.sys.time;
void main()
{
  redisContext* c;
  redisReply* reply;
  redisReply rep = redisReply();
  rep.str = cast(char*)"123";
  writeln(rep.str);
  timeval timeout = {1, 5000000}; // 1.5 seconds;
  c = redisConnectWithTimeout("127.0.0.1", 6379, timeout);
  if (c.err) {
    printf("Connection error: %s\n", c.errstr);
    exit(1);
  }
  /* Ping server */
  reply = cast(redisReply*) redisCommand(c, "PING");
  writefln("PING: %s", reply.str);
  freeReplyObject(reply);
  /* Set a key */
  writeln("set...");
  reply = cast(redisReply*) redisCommand(c, "SET foo bar");
  writefln("SET: %s", reply.str);
  freeReplyObject(reply);
  /* Get a value */
  reply = cast(redisReply*) redisCommand(c, "GET foo");
  writefln("GET: %s:%s", "foo", reply.str);
  freeReplyObject(reply);
}


