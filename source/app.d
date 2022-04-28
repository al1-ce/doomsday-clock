import std.stdio;
import std.net.curl;
import std.regex;
import std.conv: to;
import std.algorithm;
import std.string: isNumeric;
import std.array: split, replace;

const string page_url = "https://thebulletin.org/doomsday-clock/timeline/";
const string helpString = `Usage: doomsday-clock [args]

    -h, --help              Displays this message
    -y, --year              Sets cerain year for clock
    -s, --short             Displays value as clock
    -c, --seconds           Displays value in seconds
    -a, --all               Displays all known changes
`;

const auto glRegexp = regex(`(\d{4})\<.*?(it is .*? midnight)`, "gmi");
const auto shRegexp = regex(`(it|is|still|and|to|midnight|a | )`, "gi");

const int firstYear = 1947;

string toDigit(int d) {
    string res = d.to!string;
    if (d < 10) {
        res = '0' ~ res;
    }
    return res;
}

int main(string[] args) {
    // help routine
    if (args.canFind("-h") || args.canFind("--help")) {
        writeln(helpString);
        return 0;
    }
    
    string page = get!HTTP(page_url).to!string;

    auto cl = matchAll(page, glRegexp);

    string[string] arr;
    string[] keys;
    string current = "";
    foreach (str; cl) {
        // writeln(str[1], str[2]);
        arr[str[1]] = str[2];
        keys ~= str[1];
        if (current == "") {
            current = str[1];
        }
    }

    string year = "";

    if (args.canFind("-y") || args.canFind("--year")) {
        int w1idx = countUntil(args, ["-y"]).to!int;
        int w2idx = countUntil(args, ["--year"]).to!int;
        if (w1idx != -1) {
            year = args[min(w1idx + 1, args.length.to!int - 1)];
        }
        if (w2idx != -1) {
            year = args[min(w2idx + 1, args.length.to!int - 1)];
        }
    }

    if (year != "") {
        if (year in arr) {
            current = year;
        } else {
            bool up = false;
            if (year.isNumeric) {
                int y = to!int(year);
                if (y > firstYear) {
                    for (int i = 0; i < y - firstYear; i ++) {
                        string _y = (y - i).to!string;
                        if ( _y in arr ) {
                            current = _y;
                            up = true;
                            break;
                        }
                    }
                }
            }
            if (!up) {
                writeln("Unknown year.");
                return 1;
            }
        }
    }

    string value = arr[current];

    if (args.canFind("-s") || args.canFind("--short")) {
        Time t = value.compileStringTime;
        writeln(t.hours.toDigit, ":", t.minutes.toDigit, ":", t.seconds.toDigit);
        return 0;
    } else
    if (args.canFind("-c") || args.canFind("--seconds")) {
        Time t = value.compileStringTime;
        const int day = 24 * 60 * 60;
        const int time = t.hours * 60 * 60 + t.minutes * 60 + t.seconds;
        writeln(day - time);
        return 0;
    }  else
    if (args.canFind("-a") || args.canFind("--all")) {
        for (int i = 0; i < keys.length; i ++) {
            writeln(keys[i], " ", arr[keys[i]]);
        }
        return 0;
    }

    writeln(value);

    return 0;
}

Time compileStringTime(string str) {
    Time t = Time(23, 60, 60);
    string sh = str.replaceAll(shRegexp, "");
    if (sh.canFind("HALF")) {
        sh = sh.replace("HALF", "");
        t.seconds = 30;
        --t.minutes;
    }
    if (sh.canFind("MINUTES")) {
        sh = sh.replace("MINUTES", "");
        int l = sh.to!int;
        t.minutes = t.minutes - l;
    }
    if (sh.canFind("SECONDS")) {
        sh = sh.replace("SECONDS", "");
        int l = sh.to!int;
        t.seconds = t.seconds - l;
        --t.minutes;
        if (t.seconds < 0) {
            t.seconds = 60 + t.seconds;
            --t.minutes;
        }
    }
    if (t.seconds == 60) t.seconds = 0;

    return t;
}

struct Time {
    public int hours;
    public int minutes;
    public int seconds;
    
    this(int h, int m, int s) {
        this.hours = h;
        this.minutes = m;
        this.seconds = s;
    }
}
