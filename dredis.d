import core.sys.posix.sys.time;
import std.stdio;
import std.conv;
import std.string;
import hiredis;

struct RedisReply
{
  string str;
}

class DredisException : Exception
{
  this(string s) {
    super(s);
  }
}

/**
 * Contains two flavor of Redis Client
 * - Dredis (isThrow == true):  a client that throws exception when error occurs
 * - SilentDredis (isThrow == false): a client that does not throw and returns default values when error occurs.
 */
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

    public bool connect(const(char*) host, int port, int timeout)
    {
      timeval ts = {1, timeout * 1000};
      context = redisConnectWithTimeout(host, port, ts);
      if (context.err)
      {
        static if (isThrow)
        {
          throw new DredisException("Cannot connect to redis server!");
        }
        return false;
      }
      else
      {
        return true;
      }
    }

    /****************************
    * String Operations
    ***************************/

    public bool set(const(char)[] key, const(char)[] val)
    {
      return boolCmd("SET", key, val);
    }

    private string errStr(string msg)
    {
      static if (isThrow)
      {
        throw new DredisException(msg);
      }
      else
      {
        return defaultString;
      }
    }

    private long errLong(string msg)
    {
      static if (isThrow)
      {
        throw new DredisException(msg);
      }
      else
      {
        return defaultNumber;
      }
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
        case REDIS_REPLY_NIL:
          s = "nil";
          break;
        case REDIS_REPLY_ERROR:
          s = errStr(to!string(rep.str));
          break;
        default:
          s = errStr("Other");
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
    * TODO: How can I combine boolCmd with/without/withmany values?
    **/
    private bool boolCmd(string cmd, const(char)[] key)
    {
      redisReply* rep = cast(redisReply*) redisCommand(context, toStringz(cmd ~ " %s"), toStringz(key));
      bool succ = true;
      if (rep.type == REDIS_REPLY_ERROR)
      {
        succ = false;
      }
      freeReplyObject(rep);
      return succ;
    }

    private bool boolCmd(string cmd, const(char)[] key, const(char)[] val)
    {
      redisReply* rep = cast(redisReply*) redisCommand(context, toStringz(cmd ~ " %s %s"), toStringz(key), toStringz(val));
      bool succ = true;
      if (rep.type == REDIS_REPLY_ERROR)
      {
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
 * SilentDredis Client that echos no Exception.
 * When error occurs, returns a default value.
 * By default: {
 *   defaultString = "nil";
 *   defaultNumber = 0L;
 * }
 * You can specify default values with setDefaultXXX methods.
 */
alias DredisTemplate!false.Redis SilentDredis;
