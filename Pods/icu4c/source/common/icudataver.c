/*
******************************************************************************
*
*   Copyright (C) 2009-2011, International Business Machines
*   Corporation and others.  All Rights Reserved.
*
******************************************************************************
*/

#include "utypes.h"
#include "icudataver.h"
#include "ures.h"
#include "uresimp.h" /* for ures_getVersionByKey */

U_CAPI void U_EXPORT2 u_getDataVersion(UVersionInfo dataVersionFillin, UErrorCode *status) {
    UResourceBundle *icudatares = NULL;
    
    if (U_FAILURE(*status)) {
        return;
    }
    
    if (dataVersionFillin != NULL) {
        icudatares = ures_openDirect(NULL, U_ICU_VERSION_BUNDLE , status);
        if (U_SUCCESS(*status)) {
            ures_getVersionByKey(icudatares, U_ICU_DATA_KEY, dataVersionFillin, status);
        }
        ures_close(icudatares);
    }
}
