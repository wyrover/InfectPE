
// AntiSDTHookDlg.h : header file
//

#pragma once

#include "lazycat.h"

// CAntiSDTHookDlg dialog
class CAntiSDTHookDlg : public CDialog
{
// Construction
public:
	CAntiSDTHookDlg(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	enum { IDD = IDD_ANTISDTHOOK_DIALOG };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support


// Implementation
protected:
	HICON m_hIcon;

	// Generated message map functions
	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
    afx_msg void OnListCtrlDrawItemColor(NMHDR *pNmHdr, LRESULT *pResult);
	DECLARE_MESSAGE_MAP()

private:
    CListCtrl   *m_pListCtrl;
    SYSTEM_SERVICE_TABLE m_stSysSvcTab;
    PZWQUERYSYSTEMINFORMATION   ZwQuerySystemInformation;
    PZWSYSTEMDEBUGCONTROL       ZwSystemDebugControl;
public:
    afx_msg void OnBnClickedButtonRestore();
    afx_msg void OnBnClickedButtonRestoreall();
};
