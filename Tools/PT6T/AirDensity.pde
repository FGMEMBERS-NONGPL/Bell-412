static class ARDC {
    // alt(m), temp(K), Pressure Pa (N/m²), Density ro kg/m^3
    // ARDC model Atmosphere
    final static float data[][] = 
    {
       { -900.0f, 293.91f, 111679.0f, 1.32353f },
       {    0.0f, 288.11f, 101325.0f, 1.22500f },
       {  900.0f, 282.31f,  90971.0f, 1.12260f },
       { 1800.0f, 276.46f,  81494.0f, 1.02690f },
       { 2700.0f, 270.62f,  72835.0f, 0.93765f },
       { 3600.0f, 264.77f,  64939.0f, 0.85445f },
       { 4500.0f, 258.93f,  57752.0f, 0.77704f },
       { 5400.0f, 253.09f,  51226.0f, 0.70513f },
       { 6300.0f, 247.25f,  45311.0f, 0.63845f },
       { 7200.0f, 241.41f,  39963.0f, 0.57671f },
       { 8100.0f, 235.58f,  35140.0f, 0.51967f },
       { 9000.0f, 229.74f,  30800.0f, 0.46706f },
       { 9900.0f, 223.91f,  26906.0f, 0.41864f },
       { 0800.0f, 218.08f,  23422.0f, 0.37417f },
       { 1700.0f, 216.66f,  20335.0f, 0.32699f },
       { 2600.0f, 216.66f,  17654.0f, 0.28388f },
       { 3500.0f, 216.66f,  15327.0f, 0.24646f },
       { 4400.0f, 216.66f,  13308.0f, 0.21399f },
       { 5300.0f, 216.66f,  11555.0f, 0.18580f },
       { 6200.0f, 216.66f,  10033.0f, 0.16133f },
       { 7100.0f, 216.66f,   8712.0f, 0.14009f },
       { 8000.0f, 216.66f,   7565.0f, 0.12165f },
       {18900.0f, 216.66f,   6570.0f, 0.10564f },
       {19812.0f, 216.66f,   5644.0f, 0.09073f },
       {20726.0f, 217.23f,   4884.0f, 0.07831f },
       {21641.0f, 218.39f,   4235.0f, 0.06755f },
       {22555.0f, 219.25f,   3668.0f, 0.05827f },
       {23470.0f, 220.12f,   3182.0f, 0.05035f },
       {24384.0f, 220.98f,   2766.0f, 0.04360f },
       {25298.0f, 221.84f,   2401.0f, 0.03770f },
       {26213.0f, 222.71f,   2087.0f, 0.03265f },
       {27127.0f, 223.86f,   1814.0f, 0.02822f },
       {28042.0f, 224.73f,   1581.0f, 0.02450f },
       {28956.0f, 225.59f,   1368.0f, 0.02112f },
       {29870.0f, 226.45f,   1196.0f, 0.01839f },
       {30785.0f, 227.32f,   1044.0f, 0.01599f }
    };

    final static int IDX_ALT = 0;
    final static int IDX_TEMP = 1;
    final static int IDX_PRESS = 2;    
    final static int IDX_DENSITY = 3;

    ARDC() { }
    
    static float getData(float altitude, int IDX) {
        int i=0;
        float hiBound=0, loBound=0, loAlt=0, hiAlt=0;
        float ad = 0;
        
        while ( ( data[i][IDX_ALT] < altitude) && (i < data.length ) )
            i++;
        if ( i != 0 ) {
            loBound = data[i-1][IDX];
            hiBound = data[i][IDX];
            loAlt = data[i-1][IDX_ALT];
            hiAlt = data[i][IDX_ALT];
            ad = loBound + ( (altitude - loAlt) / (hiAlt - loAlt) ) * (hiBound - loBound);
        }
        else 
            ad = data[i][IDX];
           
        return ad;
    }
    
    static float getAirDensity(float altitude) {
        return getData(altitude,IDX_DENSITY);
    }
    
    static float getAirPressure(float altitude) {
        return getData(altitude,IDX_PRESS);
    }
    
    static float getAirTempK(float altitude) {
        return getData(altitude,IDX_TEMP);
    }
}
