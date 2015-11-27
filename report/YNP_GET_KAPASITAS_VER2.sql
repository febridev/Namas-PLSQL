CREATE OR REPLACE FUNCTION APPS.YNP_GET_KAPASITAS(pORG varchar2, pMesin varchar2, LINEORDER varchar2, TGL1 varchar2, TGL2 varchar2) RETURN number
IS
    rkapasitas number;
BEGIN
        select SUM(kapasitas) INTO rkapasitas
        from (
        select hou.NAME ou,
                crd.RESOURCES,
                (select operating_unit from 
                APPS.ORG_ORGANIZATION_DEFINITIONS
                where ORGANIZATION_ID = crd.organization_id ) ORG,
               crd.IDEAL_CAPACITY * 3 *
               (
                    SELECT TO_DATE(AA.INITIAL_PICKUP_DATE, 'YYYY-MM') - TO_DATE(AA.INITIAL_PICKUP_DATE, 'YYYY-MM') hari 
                            FROM WSH_NEW_DELIVERIES AA  
                            WHERE AA.DELIVERY_ID =
                                (
                                SELECT BB.DELIVERY_ID 
                                FROM WSH_DELIVERY_ASSIGNMENTS BB
                                WHERE BB.DELIVERY_DETAIL_ID = (SELECT CC.DELIVERY_DETAIL_ID 
                                                                FROM WSH_DELIVERY_DETAILS CC
                                                                WHERE CC.SOURCE_LINE_ID = LINEORDER 
                                                                AND CC.DELIVERY_DETAIL_ID  = (SELECT MAX(DD.DELIVERY_DETAIL_ID) 
                                                                    FROM WSH_DELIVERY_DETAILS DD
                                                                    WHERE DD.SOURCE_LINE_ID = LINEORDER                              
                                                                    )
                                                              )
                                )
                            AND AA.INITIAL_PICKUP_DATE BETWEEN TRUNC(TO_DATE (TGL2, 'YYYY-MM'))
                                        AND TRUNC(TO_DATE (TGL1,'YYYY-MM'))
               ) kapasitas,
               decode(crmb.RESOURCE_CLASS,
                      'BBLM','Botol Belah',
                      'CGM','CAP SHIELD',
                      'CRS','Cruiser',
                      'CUP','CUP',
                      'DRYM','Dryer',
                      'GLM','GALLON',
                      'GRM','Granulator',
                      'HDM','Blow HDPE',
                      'MIXM','Mixer',
                      'PET','PET',
                      'PLM','Pellet',
                      'PLTM','Pelletizer',
                      'PRM','PREFORM',
                      'SCM','SCREW CAP',
                      'SLPM','Slep',
                      'SSM','SSP Buhler',
                      'TCM','CAP SHIELD',
                      'TLO','Toll Out',
                      'VIBM','Vibrator',
                      'WSM','Washing') as MESIN 
        from 
            CR_RSRC_DTL crd, 
            cr_rsrc_mst_b crmb,
            hr_all_organization_units hou
        where 
        crd.INACTIVE_IND = 0
        and hou.ORGANIZATION_ID = crd.ORGANIZATION_ID
        and crmb.RESOURCES = crd.RESOURCES
        and crmb.RESOURCES not in
        (
            SELECT RESOURCES
                                                    FROM CR_RSRC_MST_B
                                                    WHERE RESOURCES like 'MLD%'
                                                        OR RESOURCES LIKE 'PUNCH%'
                                                        OR RESOURCES LIKE 'C-%'
                                                        OR RESOURCES LIKE 'C2%'
                                                        OR RESOURCES LIKE 'C3%'
        )
      
      
      )KK
       WHERE KK.ORG = pORG
        AND MESIN = pMesin;
        
       IF rkapasitas is NULL THEN
            rkapasitas := 0;
       END IF;
RETURN rkapasitas;
END;
/