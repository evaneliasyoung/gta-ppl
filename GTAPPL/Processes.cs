/**
 *  @file      Processes.cs
 *  @brief     Processed Program class.
 *
 *  @author    Evan Elias Young
 *  @date      2022-01-01
 *  @date      2022-01-01
 *  @copyright Copyright 2022 Evan Elias Young. All rights reserved.
 */

namespace GTAPPL.Threading;
public class Program : IPausable
{
    /** #region Member Variables */
    private List<Process> _procs = new List<Process>();
    /** #endregion */

    /** #region Accessors */
    public List<Process> Processes => this._procs;
    /** #endregion */

    /** #region Constructors */
    public Program() { }

    public Program(System.Diagnostics.Process[] procs)
    {
        foreach (System.Diagnostics.Process p in procs)
        {
            this._procs.Add(new Process(p));
        }
    }

    public Program(string name) : this(System.Diagnostics.Process.GetProcessesByName(name)) { }
    /** #endregion */

    /** #region Public Methods */
    public bool Suspend()
    {
        return Threading.SuspendAll(this._procs);
    }

    public bool Resume()
    {
        return Threading.ResumeAll(this._procs);
    }
    /** #endregion */
}
