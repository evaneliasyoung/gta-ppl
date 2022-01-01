/**
 *  @file      GTA.cs
 *  @brief     Main GTA class.
 *
 *  @author    Evan Elias Young
 *  @date      2022-01-01
 *  @date      2022-01-01
 *  @copyright Copyright 2022 Evan Elias Young. All rights reserved.
 */

using GTAPPL.Threading;

namespace GTAPPL;
public class GTA
{
    /** #region Member Variables */
    private Program _exe;
    /** #endregion */

    /** #region Accessors */
    public List<Process> Processes => this._exe.Processes;
    /** #endregion */

    /** #region Constructors */
    public GTA()
    {
        this._exe = new Program("GTA");
        if (this._exe.Processes.Count == 0)
        {
            throw new DllNotFoundException("failed to load GTA");
        }
    }
    /** #endregion */

    /** #region Public Methods */
    public void Suspend()
    {
        this._exe.Suspend();
    }

    public void Resume()
    {
        this._exe.Resume();
    }
    /** #endregion */
}
