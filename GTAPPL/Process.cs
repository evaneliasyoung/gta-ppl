/**
 *  @file      Process.cs
 *  @brief     Threaded Process class.
 *
 *  @author    Evan Elias Young
 *  @date      2022-01-01
 *  @date      2022-01-01
 *  @copyright Copyright 2022 Evan Elias Young. All rights reserved.
 */

namespace GTAPPL.Threading;
public class Process : IPausable
{
    /** #region Member Variables */
    private uint _id = 0;
    private List<Thread> _threads = new List<Thread>();
    /** #endregion */

    /** #region Accessors */
    public uint Id => this._id;
    public List<Thread> Threads => this._threads;
    /** #endregion */

    /** #region Constructors */
    public Process() { }

    public Process(System.Diagnostics.Process p)
    {
        if (p.Id < 0) throw new ThreadStateException();
        this._id = (uint)p.Id;
        foreach (System.Diagnostics.ProcessThread t in p.Threads)
        {
            this._threads.Add(new Thread(t.Id));
        }
    }

    public Process(int id) : this(System.Diagnostics.Process.GetProcessById(id)) { }
    /** #endregion */

    /** #region Public Methods */
    public bool Suspend()
    {
        return Threading.SuspendAll(this._threads);
    }

    public bool Resume()
    {
        return Threading.ResumeAll(this._threads);
    }
    /** #endregion */

    /** #region Overrides */
    public override string ToString()
    {
        return $"{this._id:X4}";
    }
    /** #endregion */
}
