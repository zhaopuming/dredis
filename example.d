#!/usr/bin/rdmd -L-lhiredis
import std.stdio;
import core.stdc.stdlib;
import core.sys.posix.sys.time;
import std.conv;

import dredis;

void main()
{
  redisContext* c;
  redisReply* reply;
  timeval timeout = {1, 5000000}; // 1.5 seconds;
  c = redisConnectWithTimeout("127.0.0.1", 6379, timeout);
  if (c.err) {
    printf("Connection error: %s\n", c.errstr);
    exit(1);
  }
  /* Ping server */
  void* rp = redisCommand(c, "PING");
  reply = cast(redisReply*) rp;
  writefln("PING: %s", reply.str);
  freeReplyObject(reply);
  /* Set a key */
  reply = cast(redisReply*) redisCommand(c, "SET foo ar");
  writefln("SET: %s", reply.str);
  freeReplyObject(reply);
  /* Get a value */
  reply = cast(redisReply*) redisCommand(c, "GET foo");
  writefln("GET foo: %s", *reply);
  printf(reply.str);
  freeReplyObject(reply);
}


