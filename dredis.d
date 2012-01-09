#!/usr/bin/rdmd --shebang -I/usr/include/d/hiredis -L-lhiredis
import core.sys.posix.sys.time;
import std.stdio;
import std.conv;
import std.string;
import hiredis;

struct RedisReply {
  string str;
}

class DredisException : Exception {
  this(string s) {
    super(s);
  }
}

template DredisTemplate(bool isThrow)
{
  class Redis
  {
    private redisContext* context;
    static if (!isThrow)
    {
      // TODO: Mayby default values should be config as template args
      private string defaultString = "nil";
      private long defaultNumber = 0L;

      public void setDefaultValue(string str)
      {
        defaultString = str;
      }

      public void setDefaultNumber(long number)
      {
        defaultNumber = number;
      }

    }
    public redisContext* getContext()
    {
      return context;
    }

    public void connect(const(char*) host, int ip, int timeout)
    {
      timeval ts = {1, timeout * 1000};
      context = redisConnectWithTimeout(host, ip, ts);
    }

    /****************************
    * String Operations
    ***************************/

    public bool set(const(char)[] key, const(char)[] val)
    {
      return boolCmd("SET", key, val);
    }

    public string get(const(char)[] key)
    {
      redisReply* rep = cast(redisReply*) redisCommand(context, "GET %s", toStringz(key));
      string s;
      switch (rep.type)
      {
        case REDIS_REPLY_STRING:
          s = to!string(rep.str);
          break;
        case REDIS_REPLY_ERROR:
          static if (isThrow)
          {
            throw new DredisException("haha");
          }
          else
          {
            s = defaultString;
            break;
          }
        default:
          static if (isThrow)
          {
            throw new DredisException("haha");

          }
          else
          {
            s = defaultString;
          }
      }
      freeReplyObject(rep);
      return s;
    }

    public long getLong(const(char)[] key)
    {
      redisReply* rep = cast(redisReply*) redisCommand(context, "GET %s", toStringz(key));
      long s;
      switch (rep.type)
      {
        case REDIS_REPLY_INTEGER:
          s = rep.integer;
        case REDIS_REPLY_STRING:
          // find an efficient way to conver char* to long
          // s = to!long(to!string(rep.str));
          s = std.c.stdlib.atoi(rep.str);
          break;
        case REDIS_REPLY_ERROR:
          // TODO: when in ExcMode, throw an exception
          static if (isThrow)
          {
            throw new DredisException("ahah");
          }
          else
          {
            s = defaultNumber;
          }
          break;
        default:
          static if (isThrow)
          {
            throw new DredisException("haha");
          }
          else
          {
            s = defaultNumber;
          }
          break;
      }
      freeReplyObject(rep);
      return s;
    }

    public bool del(const(char)[] key)
    {
      return boolCmd("DEL", key);
    }

    /**
    * Common implementation of boolean commands
    * TODO: should support varargs
    **/
    private bool boolCmd(string cmd, const(char)[] key, const(char)[] val = "")
    {
      redisReply* rep = cast(redisReply*) redisCommand(context, toStringz(cmd ~ " %s %s"), toStringz(key), toStringz(val));
      bool succ = true;
      if (rep.type == REDIS_REPLY_ERROR) {
        succ = false;
      }
      freeReplyObject(rep);
      return succ;
    }
  }

}

/**
 * Dredis Client. When error occurs, throws DredisException
 */
alias DredisTemplate!true.Redis Dredis;

/**
 * FastDredis Client. When error occurs, return a default value.
 * By default:
 *   defaultString = "nil";
 *   defaultNumber = 0L;
 * You can also specify default values with setDefaultXXX methods.
 */
alias DredisTemplate!false.Redis FastDredis;

void main() {
  auto r = new Dredis();
  r.connect("127.0.0.1", 6379, 5000);
  writeln(r.get("foo"));
  r.set("haha", "hooho");
  writeln(r.get("haha"));
  r.del("haha");
  writeln(r.get("mylist"));
  writeln(r.getLong("a"));
}
