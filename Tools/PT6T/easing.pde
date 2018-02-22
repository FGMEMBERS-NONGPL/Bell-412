// from C++ https://github.com/jesusgollonet/ofpennereasing
//
//@t is the current time (or position) of the tween. This can be seconds or frames, steps, seconds, ms, whatever – as long as the unit is the same as is used for the total time [3].
//@b is the beginning value of the property.
//@c is the change between the beginning and destination value of the property.
//@d is the total time of the tween.

float elasticEaseIn (float t, float b, float c, float d) {
    if ( t == 0 ) return b;  
    if ( (t/=d) == 1 ) 
        return b+c;  
    float p=d*.3f;
    float a=c; 
    float s=p/4;
    float postFix =a*pow(2, 10*(t-=1)); // this is a fix, again, with post-increment operators
    return -(postFix * sin((t*d-s)*(2*PI)/p )) + b;
}

float elasticEaseOut(float t, float b, float c, float d) {
    if (t==0) return b;  
    if ((t/=d)==1) return b+c;  
    float p=d*.3f;
    float a=c; 
    float s=p/4;
    return (a*pow(2, -10*t) * sin( (t*d-s)*(2*PI)/p ) + c + b);
}

float elasticEaseInOut(float t, float b, float c, float d) {
    if (t==0) return b;  
    if ((t/=d/2)==2) return b+c; 
    float p=d*(.3f*1.5f);
    float a=c; 
    float s=p/4;

    if (t < 1) {
        float postFix =a*pow(2, 10*(t-=1)); // postIncrement is evil
        return -.5f*(postFix* sin( (t*d-s)*(2*PI)/p )) + b;
    } 
    float postFix =  a*pow(2, -10*(t-=1)); // postIncrement is evil
    return postFix * sin( (t*d-s)*(2*PI)/p )*.5f + c + b;
}

//                    tick     min      max      dt
float linearEaseNone (float t, float b, float c, float d) {
    float v = c*t/d + b;
    //println("tick: "+t+" min: "+b+" max: "+c+" dt: "+d+" value: "+v);
    return v;
    //return c*t/d + b;
}

float linearEaseIn (float t, float b, float c, float d) {
    return c*t/d + b;
}

float linearEaseOut(float t, float b, float c, float d) {	
    return c*t/d + b;
}

float sineEaseIn (float t,float b , float c, float d) {
	return -c * cos(t/d * (PI/2)) + c + b;
}

float sineEaseOut(float t,float b , float c, float d) {	
	return c * sin(t/d * (PI/2)) + b;	
}

float sineEaseInOut(float t,float b , float c, float d) {
	return -c/2 * (cos(PI*t/d) - 1) + b;
}

float quadEaseIn (float t,float b , float c, float d) {
	return c*(t/=d)*t + b;
}
float quadEaseOut(float t,float b , float c, float d) {
	return -c *(t/=d)*(t-2) + b;
}
float quadEaseInOut(float t,float b , float c, float d) {
	if ((t/=d/2) < 1) return ((c/2)*(t*t)) + b;
	return -c/2 * (((--t)*(t-2)) - 1) + b;
        // c++ orig version swap (--t)*(t-2) => (t-2)(--t) due
        // to diff in behaviour in pre-increment -- V.S.
}

float cubicEaseIn (float t, float b, float c, float d) {
    return c*(t/=d)*t*t + b;
}
float cubicEaseOut(float t, float b, float c, float d) {
    return c*((t=t/d-1)*t*t + 1) + b;
}

float bounceEaseIn (float t, float b, float c, float d) {
    return c - bounceEaseOut (d-t, 0, c, d) + b;
}

float bounceEaseOut(float t, float b, float c, float d) {
    if ((t/=d) < (1/2.75f)) {
        return c*(7.5625f*t*t) + b;
    } 
    else if (t < (2/2.75f)) {
        float postFix = t-=(1.5f/2.75f);
        return c*(7.5625f*(postFix)*t + .75f) + b;
    } 
    else if (t < (2.5/2.75)) {
        float postFix = t-=(2.25f/2.75f);
        return c*(7.5625f*(postFix)*t + .9375f) + b;
    } 
    else {
        float postFix = t-=(2.625f/2.75f);
        return c*(7.5625f*(postFix)*t + .984375f) + b;
    }
}

float bounceEaseInOut(float t, float b, float c, float d) {
    if (t < d/2) return bounceEaseIn (t*2, 0, c, d) * .5f + b;
    else return bounceEaseOut (t*2-d, 0, c, d) * .5f + c*.5f + b;
}

float backEaseIn (float t, float b, float c, float d) {
    float s = 1.70158f;
    float postFix = t/=d;
    return c*(postFix)*t*((s+1)*t - s) + b;
}
float backEaseOut(float t, float b, float c, float d) {	
    float s = 1.70158f;
    return c*((t=t/d-1)*t*((s+1)*t + s) + 1) + b;
}

float backEaseInOut(float t, float b, float c, float d) {
    float s = 1.70158f;
    if ((t/=d/2) < 1) return c/2*(t*t*(((s*=(1.525f))+1)*t - s)) + b;
    float postFix = t-=2;
    return c/2*((postFix)*t*(((s*=(1.525f))+1)*t + s) + 2) + b;
}

float quintEaseIn (float t, float b, float c, float d) {
    return c*(t/=d)*t*t*t*t + b;
}
float quintEaseOut(float t, float b, float c, float d) {
    return c*((t=t/d-1)*t*t*t*t + 1) + b;
}

float quintEaseInOut(float t, float b, float c, float d) {
    if ((t/=d/2) < 1) return c/2*t*t*t*t*t + b;
    return c/2*((t-=2)*t*t*t*t + 2) + b;
}


public interface Easing {
    float invoke(float itick, float iminVal, float imaxVal, float idt);
}

Map<String, Easing> easings = new HashMap<String, Easing>();

void initEasings() {
    easings.put("linearEaseNone", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return linearEaseNone(itick,iminVal,imaxVal,idt); 
        }
    });
    easings.put("linearEaseIn", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return linearEaseIn(itick,iminVal,imaxVal,idt); 
        }
    });
    easings.put("linearEaseOut", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return linearEaseOut(itick,iminVal,imaxVal,idt); 
        }
    });
    easings.put("elasticEaseIn", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return elasticEaseIn(itick,iminVal,imaxVal,idt); 
        }
    });
    easings.put("elasticEaseOut", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return elasticEaseOut(itick,iminVal,imaxVal,idt); 
        }
    });
    easings.put("elasticEaseInOut", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return elasticEaseInOut(itick,iminVal,imaxVal,idt); 
        }
    });
    easings.put("cubicEaseIn", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return cubicEaseIn(itick,iminVal,imaxVal,idt); 
        }
    });
    easings.put("cubicEaseOut", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return cubicEaseOut(itick,iminVal,imaxVal,idt); 
        }
    });
    easings.put("quintEaseIn", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return quintEaseIn(itick,iminVal,imaxVal,idt); 
        }
    });
    easings.put("quintEaseOut", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return quintEaseOut(itick,iminVal,imaxVal,idt); 
        }
    });
    easings.put("quintEaseInOut", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return quintEaseInOut(itick,iminVal,imaxVal,idt); 
        }
    });    
    easings.put("sineEaseIn", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return sineEaseIn(itick,iminVal,imaxVal,idt); 
        }
    });    
    easings.put("sineEaseOut", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return sineEaseOut(itick,iminVal,imaxVal,idt); 
        }
    });
    easings.put("sineEaseInOut", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return sineEaseInOut(itick,iminVal,imaxVal,idt); 
        }
    });    
    easings.put("quadEaseIn", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return quadEaseIn(itick,iminVal,imaxVal,idt); 
        }
    });    
    easings.put("quadEaseOut", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return quadEaseOut(itick,iminVal,imaxVal,idt); 
        }
    });
    easings.put("quadEaseInOut", new Easing() {
        public float invoke(float itick, float iminVal, float imaxVal, float idt) { 
            return quadEaseInOut(itick,iminVal,imaxVal,idt); 
        }
    });
}

class Ease {

    float timerTick;        // accumulator
    String easeMethod;      // ease function to call

    Ease(String ieaseMethod) {
        timerTick = 0;
        easeMethod = ieaseMethod;    // TODO: check method name
    }
    
    // interpolate(duration_sec, value, minValue, maxValue)
    float interpolate(float duration_sec, float value, float minValue, float maxValue) {
        if ( value < maxValue ) {
            float dt = round(duration_sec * round(frameRate));
            timerTick += 1;
            value = minValue + easings.get(easeMethod).invoke(timerTick,0,maxValue-minValue,dt);
            //println("eased: "+value+", Tick: "+timerTick+", min: "+minValue+", max: "+maxValue+", dt: "+dt);
        } 
        else
            timerTick = 0;

        return value;
    }
    
    float interpolate(String ieaseMethod, float duration_sec, float value, float minValue, float maxValue) {
        if ( value < maxValue ) {
            float dt = round(duration_sec * round(frameRate));
            timerTick += 1;
            value = minValue + easings.get(ieaseMethod).invoke(timerTick,0,maxValue-minValue,dt);
            //println("eased: "+value+", Tick: "+timerTick+", min: "+minValue+", max: "+maxValue+", dt: "+dt);
        } 
        else
            timerTick = 0;

        return value;
    }
    
    void reset() { timerTick = 0; }
}
