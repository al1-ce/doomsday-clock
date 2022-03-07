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
    -a, --all               Displays all known changes
`;

const auto glRegexp = regex(`(\d{4})\<.*?(it is .*? midnight)`, "gmi");
const auto shRegexp = regex(`(it|is|still|and|to|midnight|a | )`, "gi");

const int firstYear = 1947;
int hours = 23;
int minutes = 60;
int seconds = 60;

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
        string sh = value.replaceAll(shRegexp, "");
        if (sh.canFind("HALF")) {
            sh = sh.replace("HALF", "");
            seconds = 30;
            --minutes;
        }
        if (sh.canFind("MINUTES")) {
            sh = sh.replace("MINUTES", "");
            int l = sh.to!int;
            minutes = minutes - l;
        }
        if (sh.canFind("SECONDS")) {
            sh = sh.replace("SECONDS", "");
            int l = sh.to!int;
            seconds = seconds - l;
            --minutes;
            if (seconds < 0) {
                seconds = 60 + seconds;
                --minutes;
            }
        }
        if (seconds == 60) seconds = 0;
        writeln(hours.toDigit, ":", minutes.toDigit, ":", seconds.toDigit);
        return 0;
    } else
    if (args.canFind("-a") || args.canFind("--all")) {
        for (int i = 0; i < keys.length; i ++) {
            writeln(keys[i], " ", arr[keys[i]]);
        }
        return 0;
    }

    writeln(value);

    return 0;
}
