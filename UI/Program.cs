/**
 *  @file      Program.cs
 *  @brief     Main bootstrapper for GTA-PPL.
 *
 *  @author    Evan Elias Young
 *  @date      2022-01-01
 *  @date      2022-01-01
 *  @copyright Copyright 2022 Evan Elias Young. All rights reserved.
 */

using System.Timers;
using GTAPPL;

public class Program
{
    public static readonly int HEADER_ROW = 0;
    public static readonly int STAT_ROW = 7;
    public static readonly int TIME_ROW = Program.STAT_ROW + 1;
    public static readonly int ADDR_ROW = Program.TIME_ROW + 2;
    public static readonly int MIN_SLEEP = 9;
    public static readonly int MAX_SLEEP = 11;
    public static readonly int REFRESH = 75;
    public static readonly int ADDR_DELAY = 15;
    public static Random rng = new Random();
    public static TimeSpan ms = new TimeSpan();
    public static TimeSpan pause = new TimeSpan();
    public static System.Timers.Timer writeTimer = new System.Timers.Timer();
    public static System.Timers.Timer exitTimer = new System.Timers.Timer();
    public static GTA game = new GTA();

    public enum ThreadState
    {
        INIT,
        SUSPENDED,
        RESUMED
    };

    static int WidthPercent(double percent)
    {
        return (int)Math.Ceiling(Console.WindowWidth * percent);
    }

    static int GetTextCenter(int length)
    {
        return (int)Math.Ceiling((double)(Console.WindowWidth - length) / 2);
    }

    static string PadCenter(string text)
    {
        return new string(' ', Program.GetTextCenter(text.Count()));
    }

    static void WriteCenterLine(string text)
    {
        Console.Write(Program.PadCenter(text));
        Console.WriteLine(text);
    }

    static void WriteHeader()
    {
        Console.SetCursorPosition(0, HEADER_ROW);
        Console.ForegroundColor = ConsoleColor.Cyan;
        Program.WriteCenterLine(" ██████  ████████  █████        ██████  ██████  ██      ");
        Program.WriteCenterLine("██          ██    ██   ██       ██   ██ ██   ██ ██      ");
        Program.WriteCenterLine("██   ███    ██    ███████ █████ ██████  ██████  ██      ");
        Program.WriteCenterLine("██    ██    ██    ██   ██       ██      ██      ██      ");
        Program.WriteCenterLine(" ██████     ██    ██   ██       ██      ██      ███████ ");

        Console.ForegroundColor = ConsoleColor.Yellow;
        Program.WriteCenterLine("Evan Elias Young");
        Console.ForegroundColor = ConsoleColor.White;
    }

    static void WriteStatus(string status)
    {
        Console.SetCursorPosition(0, STAT_ROW);
        Console.Write(new string(' ', Console.WindowWidth));
        Console.SetCursorPosition(0, STAT_ROW);

        Console.ForegroundColor = ConsoleColor.Magenta;
        Program.WriteCenterLine(status);
        Console.ForegroundColor = ConsoleColor.White;
    }

    static void WriteTime()
    {
        Console.SetCursorPosition(Program.GetTextCenter(4), TIME_ROW);
        Console.ForegroundColor = ConsoleColor.Green;
        Console.Write(Program.pause.ToString(@"ss\.ff"));
        Console.ForegroundColor = ConsoleColor.White;
    }

    static void WriteAddresses(ThreadState st)
    {
        int margin = Program.WidthPercent(0.15);
        int curLine = ADDR_ROW;
        Func<bool> rowDone = delegate ()
        {
            return Console.GetCursorPosition().Left >= Console.WindowWidth - margin;
        };
        Func<bool> colDone = delegate ()
        {
            return curLine == Console.WindowHeight - 2;
        };
        Func<bool> allDone = delegate ()
        {
            return colDone() && rowDone();
        };
        Action indent = delegate ()
        {
            Console.SetCursorPosition(margin, curLine++);
        };

        Console.ForegroundColor = st == ThreadState.SUSPENDED ? ConsoleColor.DarkGray : ConsoleColor.White;

        indent();
        while (!allDone())
        {
            foreach (GTAPPL.Threading.Process p in game.Processes)
            {
                foreach (GTAPPL.Threading.Thread t in p.Threads)
                {
                    if (rowDone()) indent();
                    Console.Write($"{t}  ");

                    if (allDone()) break;
                    if (st == ThreadState.INIT) System.Threading.Thread.Sleep(Program.ADDR_DELAY);
                }
                if (allDone()) break;
            }
        }
    }

    static void WriteTimerTick(Object? source, ElapsedEventArgs e)
    {
        Program.pause -= Program.ms;
        Program.WriteTime();
    }

    static void ExitTimerTick(Object? source, ElapsedEventArgs e)
    {
        Program.writeTimer.Stop();
        Program.exitTimer.Stop();
        Program.Resume();
    }

    static void Suspend()
    {
        Program.WriteStatus("suspending connection");
        Program.WriteAddresses(ThreadState.SUSPENDED);

        Program.game.Suspend();
        Program.writeTimer.Start();
        Program.exitTimer.Start();
    }

    static void Resume()
    {
        Program.WriteStatus("public/private lobby generated");
        Program.WriteAddresses(ThreadState.RESUMED);

        Program.game.Resume();
        Program.pause -= Program.pause;
        Program.WriteTime();
        Program.writeTimer.Stop();
    }

    static void SetTimeSpans()
    {
        Program.ms = new TimeSpan(0, 0, 0, 0, Program.REFRESH);
        Program.pause = new TimeSpan(0, 0, 0, Program.rng.Next(Program.MIN_SLEEP, Program.MAX_SLEEP), Program.rng.Next(0, 999));
    }

    static void SetTimers()
    {
        Program.writeTimer.Interval = Program.ms.TotalMilliseconds;
        Program.writeTimer.Elapsed += Program.WriteTimerTick;

        Program.exitTimer.Interval = Program.pause.TotalMilliseconds;
        Program.exitTimer.AutoReset = false;
        Program.exitTimer.Elapsed += Program.ExitTimerTick;
    }

    static void Main()
    {
        Console.CursorVisible = false;
        Program.SetTimeSpans();
        Program.SetTimers();

        Program.WriteHeader();
        Program.WriteTime();

        Program.WriteStatus("scanning processes");
        Program.WriteAddresses(ThreadState.INIT);

        Program.WriteStatus("locking threads");
        System.Threading.Thread.Sleep(1500);

        Program.Suspend();

        Console.ReadKey();
    }
}
