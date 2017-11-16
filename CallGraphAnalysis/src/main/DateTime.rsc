module main::DateTime

import Prelude;

public str formatDuration(Duration duration) 
{
    str output = "";
    if(duration.hours < 10) 
    {
        output += "0";
    }
    output += "<duration.hours>:";

    if(duration.minutes < 10) 
    {
        output += "0";
    }
    output += "<duration.minutes>:";

    if(duration.seconds < 10) 
    {
        output += "0";
    }
    output += "<duration.seconds>";
    return output;
}