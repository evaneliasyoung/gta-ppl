/**
 *  @file      Thread.cs
 *  @brief     Thread class.
 *
 *  @author    Evan Elias Young
 *  @date      2022-01-01
 *  @date      2022-01-01
 *  @copyright Copyright 2022 Evan Elias Young. All rights reserved.
 */

using System.Diagnostics;
using System.Runtime.InteropServices;

namespace GTAPPL.Threading;

public class Thread : IPausable
{
    /** #region DLL Imports */
    [DllImport("kernel32.dll")]
    private static extern IntPtr OpenThread(ThreadAccess Access, bool InheritHandle, uint ThreadID);
    [DllImport("kernel32.dll")]
    private static extern uint SuspendThread(IntPtr Thread);
    [DllImport("kernel32.dll")]
    private static extern int ResumeThread(IntPtr Thread);
    [DllImport("kernel32", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern bool CloseHandle(IntPtr Handle);
    /** #endregion */

    /** #region Types */
    [Flags]
    public enum ThreadAccess : uint
    {
        TERMINATE = 0x0001,
        SUSPEND_RESUME = 0x0002,
        GET_CONTEXT = 0x0008,
        SET_CONTEXT = 0x0010,
        SET_INFORMATION = 0x0020,
        QUERY_INFORMATION = 0x0040,
        SET_THREAD_TOKEN = 0x0080,
        IMPERSONATE = 0x0100,
        DIRECT_IMPERSONATION = 0x0200
    }
    /** #endregion */

    /** #region Member Variables */
    private uint _id = 0;
    private IntPtr _handle = IntPtr.Zero;
    /** #endregion */

    /** #region Accessors */
    public uint Id => this._id;
    /** #endregion */

    /** #region Private Methods */
    private bool _OpenHandle()
    {
        this._handle = OpenThread(ThreadAccess.SUSPEND_RESUME, false, this._id);
        return this._handle != IntPtr.Zero;
    }

    private bool _CloseHandle()
    {
        return CloseHandle(this._handle);
    }
    /** #endregion */

    /** #region Constructors */
    public Thread() { }

    public Thread(int id)
    {
        if (id < 0) throw new ThreadStateException();
        this._id = (uint)id;
    }

    public Thread(ProcessThread t) : this(t.Id) { }
    /** #endregion */

    /** #region Public Methods */
    public bool Suspend()
    {
        if (!this._OpenHandle()) return false;
        SuspendThread(this._handle);
        if (!this._CloseHandle()) return false;
        return true;
    }

    public bool Resume()
    {
        if (!this._OpenHandle()) return false;
        for (int suspendCount = 1; suspendCount > 0; suspendCount = ResumeThread(this._handle));
        if (!this._CloseHandle()) return false;
        return true;
    }
    /** #endregion */

    /** #region Overrides */
    public override string ToString()
    {
        return $"{this._id:X4}";
    }
    /** #endregion */
}
