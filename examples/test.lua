set_console_mode(true)

local last_pi = 0
local last_super_pi = 0

local ert_string = string.rep("_", 128)
local rt_a = string.rep("_", 64)
local rt_b = string.rep("_", 64)
local lps = string.rep("_", 32)

local ptyn_toggle = false
local ptyn = string.rep(" ", 8)

local odas = {}
local ert_display = ""

local last_rt = true
local rta_display = ""
local rtb_display = ""
local lps_display = ""

local current_menu = 1

local pty_rds = {
    "None", "News", "Current Affairs",
    "Information", "Sport", "Education",
    "Drama", "Culture", "Science",
    "Varied speech", "Pop", "Rock",
    "Easy listening", "Light classic", "Classic",
    "Other", "Weather", "Finance",
    "Children's", "Social", "Religion",
    "Phone in", "Travel", "Leisure",
    "Jazz", "Country", "National",
    "Oldies", "Folk", "Documentary",
    "Alarm Test", "Alarm !",
}
local pty_rbds = {
    "None", "News", "Information",
    "Sports", "Talk", "Rock",
    "Classic Rock", "Adult Hits", "Soft Rock",
    "Top 40", "Country", "Oldies",
    "Soft", "Nostalgia", "Jazz",
    "Classical", "R&B", "Soft R&B",
    "Foreign Language", "Religious Music", "Religious Talk",
    "Personality", "Public", "College",
    "Spanish Talk", "Spanish Music", "Hip-Hop",
    "???", "???", "Weather",
    "Emergency Test", "ALERT !",
}
local pty = 0

local tp = false
local ta = false
local dpty = false

local ecc = 0
local pi_code_to_country = {
    "Encoder fault / PI not received",
    "CM DE GR KW MA MD ME NA SL AI BO GT PR US VI AUS-CT KI LA",
    "CF CZ DZ EE IE LR QA ZW AG CO HN PR US VI AUS-NSW BT TH",
    "PL AD DJ EH GH KG MK MZ SM TR AW BR JM PR US VI AUS-V BD KH TO",
    "Cabinda CH IL MG MR UG VA FK MQ PR US VI AUS-Q PK WS",
    "IT JO ML RW SK ST SZ TJ BB MS PR US VI AUS-SA FJ IN",
    "AO BE CV FI KE LS OM SY UA BZ PR TT US VI AUS-WA MO",
    "GQ Kosovo LU RU SN SO TN KY NI PR US VI AUS-T NR VN",
    "BG GA GM NE NL PS PT SC CR PR SR US VI AUS-NT CH IR PH",
    "AL BI DK GN LI LV SA SI TD CU PA PR US UY VI CH JP NZ PG",
    "AM AT GI GW IS LB MU SH SS ZA AR DM PR KN US VI AF SG SB",
    "AZ BF BW CD HU IQ MC UZ YE BR CA DO MX PR LC US VI BN MV MH MM",
    "CG CI GB GE HR KM LT MT SD BM BR CA CL SN PR VC US VI CH ID LK",
    "AE DE KZ LY RS TG TZ BR CA GD HT MX AN PR US VI KP TW", -- kp is the best here man, also tw? wtf
    "Bahrein BJ ES ET RO SE TM ZM CA GP MX TB PR US VE VI KR FM NP",
    "BA BY EG ER FR MN MW NG NO BS GL GY MX PM VG HK MY VU",
}

local pi_ecc_to_country = {
    e0 =  {
        "Encoder fault", -- 0
        "Federal Republic of Germany", -- 1
        "People's Democratic Republic of Algeria", -- 2
        "Principality of Andorra", -- 3
        "State of Israel", -- 4
        "Italian Republic", -- 5
        "Kingdom of Belgium", -- 6
        "Russian Federation", -- 7
        "State of Palestine", -- 8
        "Republic of Albania", -- 9
        "Federal Republic of Austria", -- 10 A
        "Hungary", -- 11 B
        "Republic of Malta", -- 12 C
        "Federal Republic of Germany", -- 13 D
        "Unknown", -- 14 E
        "Arab Republic of Egypt", -- 15 F
    },
    e1 =  {
        "Encoder fault", -- 0
        "Hellenic Republic (Greece)", -- 1
        "Libya", -- 2
        "Republic of San Marino", -- 3
        "Swiss Confederation", -- 4
        "Hashemite Kingdom of Jordan", -- 5
        "Republic of Finland", -- 6
        "Grand Duchy of Luxembourg", -- 7
        "Republic of Bulgaria", -- 8
        "Kingdom of Denmark", -- 9
        "United Kingdom of Great Britain and Northern Ireland (Gibraltar)", -- 10 A
        "Republic of Iraq", -- 11 B
        "United Kingdom of Great Britain and Northern Ireland", -- 12 C
        "Unknown", -- 13 D
        "Romania", -- 14 E
        "Republic of France", -- 15 F wish i could nuke this
    },
    e2 =  {
        "Encoder fault", -- 0
        "Kingdom of Morocco", -- 1
        "Czech Republic", -- 2
        "Republic of Poland", -- 3
        "Vatican City State", -- 4 : not an UN member, had to google them and not just copy from the pdf
        "Slovak Republic", -- 5
        "Syrian Arab Republic", -- 6
        "Republic of Tunisia", -- 7
        "Unknown", -- 8
        "Principality of Liechtenstein", -- 9
        "Republic of Iceland", -- 10 A
        "Principality of Monaco", -- 11 B
        "Republic of Lithuania", -- 12 C
        "Republic of Serbia", -- 13 D
        "Kingdom of Spain", -- 14 E
        "Kingdom of Norway", -- 15 F
    },
    e3 =  {
        "Encoder fault", -- 0
        "Montenegro", -- 1
        "Ireland", -- 2
        "Republic of Turkey", -- 3
        "Unknown", -- 4
        "Republic of Tajikistan", -- 5
        "Unknown", -- 6
        "Unknown", -- 7
        "Kingdom of the Netherlands", -- 8
        "Republic of Latvia", -- 9
        "Republic of Lebanon", -- 10 A
        "Republic of Azerbaijan", -- 11 B
        "Republic of Croatia", -- 12 C
        "Republic of Kazakhstan", -- 13 D
        "Kingdom of Sweden", -- 14 E
        "Republic of Belarus", -- 15 F
    },
    e4 =  {
        "Encoder fault", -- 0
        "Republic of Moldova", -- 1
        "Republic of Estonia", -- 2
        "The former Yugoslav Republic of Macedonia", -- 3
        "Unknown", -- 4
        "Unknown", -- 5
        "Ukraine", -- 6
        "Republic of Kosovo", -- 7 : had to google this one too, no un
        "Republic of Portugal", -- 8
        "Republic of Slovenia", -- 9
        "Republic of Armenia", -- 10 A
        "Republic of Uzbekistan", -- 11 B
        "Georgia", -- 12 C
        "Unknown", -- 13 D
        "Turkmenistan", -- 14 E
        "Bosnia and Herzegovina", -- 15 F
    },
    e5 =  {
        "Encoder fault", -- 0
        "Unknown", -- 1
        "Unknown", -- 2
        "Kyrgyz Republic (Kyrgyzstan)", -- 3
        "Unknown", -- 4
        "Unknown", -- 5
        "Unknown", -- 6
        "Unknown", -- 7
        "Unknown", -- 8
        "Unknown", -- 9
        "Unknown", -- 10 A
        "Unknown", -- 11 B
        "Unknown", -- 12 C
        "Unknown", -- 13 D
        "Unknown", -- 14 E
        "Unknown", -- 15 F
    },
    a0 = {
        "Encoder fault", -- 0
        "United States of America", -- 1
        "United States of America", -- 2
        "United States of America", -- 3
        "United States of America", -- 4
        "United States of America", -- 5
        "United States of America", -- 6
        "United States of America", -- 7
        "United States of America", -- 8
        "United States of America", -- 9
        "United States of America", -- 10 A
        "United States of America", -- 11 B
        "United States of America", -- 12 C
        "United States of America", -- 13 D
        "United States of America", -- 14 E
        -- fucking great
        "Unknown", -- 15 F
    },
    a1 = {
        "Encoder fault", -- 0
        "Unknown", -- 1
        "Unknown", -- 2
        "Unknown", -- 3
        "Unknown", -- 4
        "Unknown", -- 5
        "Unknown", -- 6
        "Unknown", -- 7
        "Unknown", -- 8
        "Unknown", -- 9
        "Unknown", -- 10 A
        "Canada", -- 11 B
        "Canada", -- 12 C
        "Canada", -- 13 D
        "Cananda", -- 14 E
        "Greenland", -- 15 F
    },
    a2 = {
        "Encoder fault", -- 0
        "United Kingdom of Great Britain and Northern Ireland (Anguilla)", -- 1
        "Antigua and Barbuda", -- 2
        "Federative Republic of Brazil / Republic of Ecuador", -- 3 : R22_039_1 has a fucking error, its not "Ecuador", but fucking "Equator"? THE FUCKING STANDARD HAS A WRONG COUNTRY NAME
        "United Kingdom of Great Britain and Northern Ireland (Falkland Islands)", -- 4
        "Barbados", -- 5
        "Belize", -- 6
        "United Kingdom of Great Britain and Northern Ireland (Cayman Islands)", -- 7
        "Republic of Costa Rica", -- 8
        "Republic of Cuba", -- 9
        "Republic of Argentina", -- 10 A
        "Federative Republic of Brazil", -- 11 B
        "United Kingdom of Great Britain and Northern Ireland (Bermuda) / Federative Republic of Brazil", -- 12 C
        "Netherlands Antilles (governemnt does not exist) / Federative Republic of Brazil", -- 13 D : Yes, it ceased to exist in 2010 but its not like they care
        "Republic of France (Guadeloupe)", -- 14 E
        "Commonwealth of the Bahamas", -- 15 F
    },
    a3 = {
        "Encoder fault", -- 0
        "Plurinational State of Bolivia", -- 1
        "Republic of Colombia", -- 2
        "Jamaica", -- 3
        "Republic of France (Martinique)", -- 4
        "Unknown", -- 5
        "Republic of Paraguay", -- 6
        "Republic of Nicaragua", -- 7
        "Unknown", -- 8
        "Republic of Panama", -- 9
        "Commonwealth of Dominica", -- 10 A
        "Dominican Republic", -- 11 B
        "Republic of Chile", -- 12 C
        "Grenada", -- 13 D
        "United Kingdom of Great Britain and Northern Ireland (Turks and Caicos Islands)", -- 14 E
        "Republic of Guyana", -- 15 F
    },
    a4 = {
        "Encoder fault", -- 0
        "Republic of Guatemala", -- 1
        "Republic of Honduras", -- 2
        "Kingdom of the Netherlands (Aruba)", -- 3
        "Unknown", -- 4
        "United Kingdom of Great Britain and Northern Ireland (Montserrat)", -- 5
        "Republic of Trinidad and Tobago", -- 6
        "Republic of Peru", -- 7
        "Republic of Suriname", -- 8
        "Oriental Republic of Uruguay", -- 9
        "Saint Kitts and Nevis", -- 10 A
        "Saint Lucia", -- 11 B
        "Republic of El Salvador", -- 12 C
        "Republic of Haiti", -- 13 D
        "Bolivarian Republic of Venezuela", -- 14 E
        "United Kingdom of Great Britain and Northern Ireland (Virgin Islands)", -- 15 F
    },
    a5 = {
        "Encoder fault", -- 0
        "Unknown", -- 1
        "Unknown", -- 2
        "Unknown", -- 3
        "Unknown", -- 4
        "Unknown", -- 5
        "Unknown", -- 6
        "Unknown", -- 7
        "Unknown", -- 8
        "Unknown", -- 9
        "Unknown", -- 10 A
        "United Mexican States", -- 11 B
        "Saint Vincent and the Grenadines", -- 12 C
        "United Mexican States", -- 13 D
        "United Mexican States", -- 14 E
        "United Mexican States", -- 15 F
    },
    d0 = {
        "Encoder fault", -- 0
        "Republic of Cameroon", -- 1
        "Central African Republic", -- 2
        "Republic of Djibouti", -- 3
        "Republic of Madagascar", -- 4
        "Republic of Mali", -- 5
        "Republic of Angola", -- 6
        "Republic of Equatorial Guinea", -- 7
        "Gabonese Republic", -- 8
        "Republic of Guinea", -- 9
        "Republic of South Africa", -- 10 A
        "Burkina Faso", -- 11 B
        "Republic of the Congo", -- 12 C
        "Republic of Togo", -- 13 D
        "Republic of Benin", -- 14 E
        "Republic of Malawi", -- 15 F
    },
    d1 = {
        "Encoder fault", -- 0
        "Republic of Namibia", -- 1
        "Republic of Liberia", -- 2
        "Republic of Ghana", -- 3
        "Islamic Republic of Mauritania", -- 4
        "Democratic Republic of Sao Tome and Principe", -- 5
        "Republic of Cabo Verde (Capo Verde)", -- 6
        "Republic of Senegal", -- 7
        "Islamic Republic of the Gambia", -- 8
        "Republic of Burundi", -- 9
        "United Kingdom of Great Britain and Northern Ireland (Ascension Island)", -- 10 A
        "Republic of Botswana", -- 11 B
        "Union of the Comoros", -- 12 C
        "United Republic of Tanzania", -- 13 D
        "Federal Democratic Republic of Ethiopia", -- 14 E
        "Federal Republic of Nigeria", -- 15 F : nigeria haha
    },
    d2 = {
        "Encoder fault", -- 0
        "Republic of Sierra Leone", -- 1
        "Republic of Zimbabwe", -- 2
        "Republic of Mozambique", -- 3
        "Republic of Uganda", -- 4
        "Kingdom of Swaziland", -- 5
        "Republic of Kenya", -- 6
        "Federal Republic of Somalia", -- 7
        "Republic of the Niger", -- 8 : niger haha
        "Republic of Chad", -- 9
        "Republic of Guinea-Bissau", -- 10 A
        "Democratic Republic of the Congo", -- 11 B
        "Republic of Côte d'Ivoire (Ivory Coast)", -- 12 C
        "Unknown", -- 13 D
        "Republic of Zambia", -- 14 E
        "State of Eritrea", -- 15 F
    },
    d3 = {
        "Encoder fault", -- 0
        "Unknown", -- 1
        "Unknown", -- 2
        "Polisario Front / Kingdom of Morocco (Western Sahara)", -- 3
        "Republic of Cabinda / Republic of Angola", -- 4 : intresting
        "Republic of Rwanda", -- 5
        "Kingdom of Lesotho", -- 6
        "Unknown", -- 7
        "Republic of Seychelles", -- 8
        "Unknown", -- 9
        "Republic of Mauritius", -- 10 A
        "Unknown", -- 11 B
        "Republic of the Sudan", -- 12 C
        "Unknown", -- 13 D
        "Unknown", -- 14 E
        "Unknown", -- 15 F
    },
    d4 = {
        "Encoder fault", -- 0
        "Unknown", -- 1
        "Unknown", -- 2
        "Unknown", -- 3
        "Unknown", -- 4
        "Unknown", -- 5
        "Unknown", -- 6
        "Unknown", -- 7
        "Unknown", -- 8
        "Unknown", -- 9
        "Republic of South Sudan", -- 10 A
        "Unknown", -- 11 B
        "Unknown", -- 12 C
        "Unknown", -- 13 D
        "Unknown", -- 14 E
        "Unknown", -- 15 F
        -- Just one?
    },
    f0 = {
        "Encoder fault", -- 0
        "Commonwealth of Australia - Capital Territory", -- 1
        "Commonwealth of Australia - New South Wales", -- 2
        "Commonwealth of Australia - Victoria", -- 3
        "Commonwealth of Australia - Queensland", -- 4
        "Commonwealth of Australia - South Australia", -- 5
        "Commonwealth of Australia - Western Australia", -- 6
        "Commonwealth of Australia - Tasmania", -- 7
        "Commonwealth of Australia - Northern Territory", -- 8 : why tf is australia the only one like this, was the ecc code designers from there?
        "Kingdom of Saudi Arabia", -- 9
        "Islamic Republic of Afghanistan", -- 10 A
        "Republic of the Union of Myanmar (Burma)", -- 11 B
        "People's Republic of China", -- 12 C
        "Democratic People's Republic of Korea (North Korea)", -- 13 D : what if i start transmitting with ECC f0 and pi D000, AND PLAY SOUTH KOREAN MUSIC
        "Kingdom of Bahrain", -- 14 E : docs refer to it as Bahrein with no iso code
        "Malaysia", -- 15 F
    },
    f1 = {
        "Encoder fault", -- 0
        "Republic of Kiribati", -- 1
        "Kingdom of Bhutan", -- 2
        "People's Republic of Bangladesh", -- 3
        "Islamic Republic of Pakistan", -- 4
        "Republic of Fiji", -- 5
        "Sultanate of Oman", -- 6
        "Republic of Nauru", -- 7
        "Islamic Republic of Iran", -- 8
        "New Zealand", -- 9
        "Solomon Islands", -- 10 A
        "Negara Brunei Darussalam", -- 11 B
        "Democratic Socialist Republic of Sri Lanka", -- 12 C
        "Republic of China (Taiwan)", -- 13 D
        "Republic of Korea (South Korea)", -- 14 E
        "People's Republic of China (Hong Kong)", -- 15 F
    },
    f2 = {
        "Encoder fault", -- 0
        "State of Kuwait", -- 1
        "State of Qatar", -- 2
        "Kingdom of Cambodia", -- 3
        "Independent State of Samoa", -- 4
        "Republic of India", -- 5
        "People's Republic of China (Macao)", -- 6
        "Socialist Republic of Viet Nam", -- 7
        "Republic of the Philippines", -- 8
        "Japan", -- 9
        "Republic of Singapore", -- 10 A
        "Republic of Maldives", -- 11 B
        "Republic of Indonesia", -- 12 C
        "United Arab Emirates", -- 13 D
        "Federal Democratic Republic of Nepal", -- 14 E : discord election ahh
        "Republic of Vanuatu", -- 15 F : apparantly this is un but i don't have it on the pdf?
    },
    f3 = {
        "Encoder fault", -- 0
        "Lao People's Democratic Republic", -- 1
        "Kingdom of Thailand", -- 2
        "Kingdom of Tonga", -- 3
        "Unknown", -- 4
        "Unknown", -- 5
        "Unknown", -- 6
        "Unknown", -- 7
        "People's Republic of China", -- 8
        "Independent State of Papua New Guinea", -- 9
        "Unknown", -- 10 A
        "Republic of Yemen", -- 11 B
        "Unknown", -- 12 C
        "Unknown", -- 13 D
        "Federated States of Micronesia", -- 14 E
        "Mongolia", -- 15 F
    },
}

local pi_coverage = {
    "Local",
    "International",
    "National",
    "Supra-regional",
    "Regional 4",
    "Regional 5",
    "Regional 5",
    "Regional 7",
    "Regional 8",
    "Regional 9",
    "Regional A",
    "Regional B",
    "Regional C",
    "Regional D",
    "Regional E",
    "Regional F",
}

local time_display_utc = "-"
local time_display_local = "-"
local time_display_offset = 0

local last_render_hash = 0
local function crc(data)
    local crc = 0xFF

    for i = 1, #data do
        crc = crc ~ data:byte(i)

        for _ = 1, 8 do
            if (crc & 0x80) ~= 0 then crc = (crc << 1) ~ 0x7
            else crc = crc << 1 end
            crc = crc & 0xFF
        end
    end

    return crc
end

function render_menu()
    out = string.format("Menu %d\r\n------\r\n", current_menu)
    set_font_size(26)
    if current_menu == 1 then
        set_font_size(72) -- largest as i can do, this is directly from the public's wants (https://pira.cz/forum/index.php?topic=1124.0)
        out = out .. string.format("PI: %X (SPI: %X)\r\n", last_pi, last_super_pi)
        out = out .. string.format("PS: %s", db.read_value("PS") or "--------")
    elseif current_menu == 2 then
        out = out .. string.format("PTY: %d (%s / %s)\r\n", pty, pty_rds[pty+1], pty_rbds[pty+1])
        out = out .. string.format("TP %s | TA %s | DPTY %s\r\n", tp and "+" or "-", ta and "+" or "-", dpty and "+" or "-")
        out = out .. string.format("PTYN: %s\r\n\r\n", ptyn)
        out = out .. string.format("RT[A]: %s%s\r\n", last_rt and ">" or " ", rta_display)
        out = out .. string.format("RT[B]: %s%s\r\n\r\n", (not last_rt) and ">" or " ", rtb_display)
    elseif current_menu == 3 then
        local country_id = (last_pi & 0xF000) >> 12
        local coverage_id = (last_pi & 0xF00) >> 8

        out = out .. string.format("LPS: %s\r\n\r\n", lps_display)

        local country_name = "Unknown"
        local ecc_key = string.format("%x", ecc)

        if ecc ~= 0 and pi_ecc_to_country[ecc_key] and pi_ecc_to_country[ecc_key][country_id + 1] then country_name = pi_ecc_to_country[ecc_key][country_id + 1]
        elseif ecc == 0 then country_name = pi_code_to_country[country_id+1] end
        out = out .. string.format("Coverage: %s\r\n", pi_coverage[coverage_id+1])
        out = out .. string.format("Country: %s (%X)\r\n\r\n", country_name, ecc)

        out = out .. string.format("ERT: %s\r\n\r\n", ert_display)

        local oda_string = ""
        for grp, data in pairs(odas) do
            local ver_char = (data.version == 0) and "A" or "B"
            oda_string = oda_string .. string.format("%d%s - %04X | ", grp, ver_char, data.aid)
        end
        out = out .. string.format("ODA: %s\r\n", oda_string:sub(1, #oda_string-2))
    elseif current_menu == 4 then
        if time_display_offset > 2 then
            out = out .. string.format("RDS-System time offset: %d seconds\r\n", time_display_offset)
        else out = out .. string.format("RDS-System time offset: ~0\r\n") end
        out = out .. string.format("Local time: %s\r\n", time_display_local)
        out = out .. string.format("UTC time: %s\r\n", time_display_utc)
    end

    local hash = crc(out)
    if hash ~= last_render_hash then
        set_console(out)
        last_render_hash = hash
    end
end

function event(event)
    current_menu = event
    render_menu()
end

local function ternary(cond, a, b)
    if cond then return a else return b end
end

function command(cmd, param)
    if cmd:lower() == "request" and param:lower() == "decoderdata" then
        db.add_value("RT.A", rta_display)
        db.add_value("RT.B", rtb_display)
        db.add_value("RT.Type", ternary(last_rt, "0", "1"))
        db.add_value("PTYN", ptyn)
        db.add_value("ERT", ert_display)
        db.add_value("TP", "1" and tp or "0")
        db.add_value("TA", "1" and ta or "0")
        db.add_value("DI", "8" and dpty or "0")
        db.add_value("PTY.Code", tostring(pty))
        db.add_value("PTY.Name", string.format("%s / %s", pty_rds[pty+1], pty_rbds[pty+1]))
        db.add_value("ECC", string.format("%X", ecc))
        db.add_value("LPS", lps_display)
    elseif cmd:lower() == "resetdata" then
        ert_string = string.rep("_", 128)
        rt_a = string.rep("_", 64)
        rt_b = string.rep("_", 64)
        odas = {}
        last_pi = 0
        last_super_pi = 0
        pty = 0
        tp = false
        ta = false
        dpty = false
        ptyn = string.rep(" ", 8)
        ptyn_toggle = false
        ecc = 0
        lps = string.rep("_", 32)
        time_display_utc = "-"
        time_display_local = "-"
        time_display_offset = 0
    elseif cmd:lower() == "superpi" then
        if #param <= 4 then last_super_pi = tonumber(param, 16) end
    end
end

local function findODAByAID(t, targetAID)
    for grp, data in pairs(t) do
        if data.aid == targetAID then return grp, data.version end
    end
    return nil, nil
end

local function dateToEpoch(year, month, day)
    local daysInMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

    local function isLeapYear(y)
        return (y % 4 == 0 and y % 100 ~= 0) or (y % 400 == 0)
    end

    if year < 2025 or month < 1 or month > 12 or day < 1 or day > 31 then error(string.format("%d %d %d", year, month, day), 2) end

    local totalDays = 0
    for y = 2025, year - 1 do
        totalDays = totalDays + (isLeapYear(y) and 366 or 365)
    end

    for m = 1, month - 1 do
        local days = daysInMonth[m]
        if m == 2 and isLeapYear(year) then days = 29 end
        totalDays = totalDays + days
    end

    totalDays = totalDays + (day - 1)

    return totalDays * 86400
end

local function epochToDate(epochSeconds)
    local totalDays = math.floor(epochSeconds / 86400)

    local remainingSeconds = epochSeconds % 86400
    local hour = math.floor(remainingSeconds / 3600)
    local minute = math.floor((remainingSeconds % 3600) / 60)

    local year = 2025

    local function isLeapYear(y)
        return (y % 4 == 0 and y % 100 ~= 0) or (y % 400 == 0)
    end

    while true do
        local daysInYear = isLeapYear(year) and 366 or 365
        if totalDays < daysInYear then break end
        totalDays = totalDays - daysInYear
        year = year + 1
    end

    local daysInMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if isLeapYear(year) then daysInMonth[2] = 29 end

    local month = 1
    for m = 1, 12 do
        if totalDays < daysInMonth[m] then break end
        totalDays = totalDays - daysInMonth[m]
        month = month + 1
    end

    return year, month, totalDays + 1, hour, minute
end

local function getDayOfWeek(year, month, day)
    if month < 3 then
        month = month + 12
        year = year - 1
    end

    local K = year % 100
    local J = math.floor(year / 100)

    local h = (day + math.floor(13 * (month + 1) / 5) + K + math.floor(K / 4) + math.floor(J / 4) - 2 * J) % 7

    return ((h + 5) % 7) + 1
end

function group(stream, b_corr, a, b, c, d)
    if stream ~= 0 and a ~= 0 then return
    elseif stream ~= 0 and not db.load_boolean("rdsspy.ini", "General", "Tunnelling", false) then return end

    if a > 0 then last_pi = a end

    render_menu()

    if b_corr or b < 0 then return end

    pty = (b >> 5) & 0x1f
    tp = ((b >> 10) & 1) ~= 0

    local group_type = (b & 0xf000) >> 12
    local group_version = (b & 0x800) >> 11

    if group_type == 3 and group_version == 0 then
        if d < 0 then return end
        local target_group = (b & 0x1f) >> 1

        if odas[target_group] == nil then odas[target_group] = { aid = d, version = (b & 1) } end
    else
        local ert_grp, ert_ver = findODAByAID(odas, 0x6552)

        if ert_grp and group_type == ert_grp and group_version == ert_ver then
            local ert_state = b & 0x1f
            local new_chars = string.char((c >> 8) & 0xff) .. string.char(c & 0xff) .. string.char((d >> 8) & 0xff) .. string.char(d & 0xff)
            local start_pos = (ert_state * 4) + 1
            ert_string = ert_string:sub(1, start_pos - 1) .. new_chars .. ert_string:sub(start_pos + 4)

            local carriage = ert_string:find("\r", 1, true)
            if carriage then ert_display = ert_string:sub(1, carriage - 1)
            else ert_display = ert_string:gsub("%s+$", "") end
        else
            if group_type == 0 then
                ta = ((b & 0x10) >> 4) ~= 0
                local di_bit = ((b & 0x4) >> 2) ~= 0
                local segment = b & 0x3
                if di_bit and segment == 0 then dpty = true
                elseif segment == 0 then dpty = false end
            elseif group_type == 1 and group_version == 0 then
                if d < 0 then return end
                local variant = (c & 0x7000) >> 12
                if variant == 0 then ecc = c & 0xfff end
            elseif group_type == 10 and group_version == 0 then
                local toggle = ((b & 0x10) >> 4) ~= 0
                if toggle ~= ptyn_toggle then
                    ptyn = string.rep(" ", 8)
                    ptyn_toggle = toggle
                end
                local segment = b & 1
                local start_pos = (segment * 4) + 1
                local new_chars
                if d > 0 and c > 0 then
                    new_chars = string.char(db.char_conv((c >> 8) & 0xff)) .. string.char(db.char_conv(c & 0xff)) .. string.char(db.char_conv((d >> 8) & 0xff)) .. string.char(db.char_conv(d & 0xff))
                elseif c > 0 then
                    new_chars = string.char(db.char_conv((c >> 8) & 0xff)) .. string.char(db.char_conv(c & 0xff))
                elseif d > 0 then
                    new_chars = ptyn:sub(start_pos, start_pos + 1) .. string.char(db.char_conv((d >> 8) & 0xff)) .. string.char(db.char_conv(d & 0xff))
                else return end
                ptyn = ptyn:sub(1, start_pos - 1) .. new_chars .. ptyn:sub(start_pos + #new_chars)
            elseif group_type == 2 and group_version == 0 then -- TODO 2B
                local rt_state = b & 0xF
                local rt_toggle = (b >> 4) & 1
                local start_pos = (rt_state * 4) + 1

                local new_chars
                if d > 0 and c > 0 then
                    new_chars = string.char(db.char_conv((c >> 8) & 0xff)) .. string.char(db.char_conv(c & 0xff)) .. string.char(db.char_conv((d >> 8) & 0xff)) .. string.char(db.char_conv(d & 0xff))
                elseif c > 0 then
                    new_chars = string.char(db.char_conv((c >> 8) & 0xff)) .. string.char(db.char_conv(c & 0xff))
                elseif d > 0 then
                    if rt_toggle == 0 then new_chars = rt_a:sub(start_pos, start_pos + 1) .. string.char(db.char_conv((d >> 8) & 0xff)) .. string.char(db.char_conv(d & 0xff))
                    else new_chars = rt_b:sub(start_pos, start_pos + 1) .. string.char(db.char_conv((d >> 8) & 0xff)) .. string.char(db.char_conv(d & 0xff)) end
                else return end

                if rt_toggle == 0 then
                    if last_rt ~= true then rt_a = string.rep("_", 64) end
                    last_rt = true
                    rt_a = rt_a:sub(1, start_pos - 1) .. new_chars .. rt_a:sub(start_pos + #new_chars)

                    local carriage = rt_a:find("\r", 1, true)
                    if carriage then rta_display = rt_a:sub(1, carriage - 1)
                    else rta_display = rt_a:gsub("%s+$", "") end
                else
                    if last_rt ~= false then rt_b = string.rep("_", 64) end
                    last_rt = false
                    rt_b = rt_b:sub(1, start_pos - 1) .. new_chars .. rt_b:sub(start_pos + #new_chars)

                    local carriage = rt_b:find("\r", 1, true)
                    if carriage then rtb_display = rt_b:sub(1, carriage - 1)
                    else rtb_display = rt_b:gsub("%s+$", "") end
                end
            elseif group_type == 15 and group_version == 0 then
                local state = b & 7
                local start_pos = (state * 4) + 1
                local new_chars
                if d > 0 and c > 0 then
                    new_chars = string.char(db.char_conv((c >> 8) & 0xff)) .. string.char(db.char_conv(c & 0xff)) .. string.char(db.char_conv((d >> 8) & 0xff)) .. string.char(db.char_conv(d & 0xff))
                elseif c > 0 then
                    new_chars = string.char(db.char_conv((c >> 8) & 0xff)) .. string.char(db.char_conv(c & 0xff))
                elseif d > 0 then
                    new_chars = lps:sub(start_pos, start_pos + 1) .. string.char(db.char_conv((d >> 8) & 0xff)) .. string.char(db.char_conv(d & 0xff))
                else return end
                lps = lps:sub(1, start_pos - 1) .. new_chars .. lps:sub(start_pos + #new_chars)

                local carriage = lps:find("\r", 1, true)
                if carriage then lps_display = lps:sub(1, carriage - 1)
                else lps_display = lps:gsub("%s+$", "") end
            elseif group_type == 4 and group_version == 0 then
                if d < 0 or c < 0 then return end
                local system_time = os.time()
                local mjd = ((b & 7) << 15) | c >> 1
                local year = math.floor((mjd - 15078.2) / 365.25)
                local month = math.floor((mjd - 14956.1 - math.floor(year * 365.25)) / 30.6001)
                local day = mjd - 14956 - math.floor(year * 365.25) - math.floor(month * 30.6001)
                local k = 0
                if month == 14 or month == 15 then k = 1 end
                year = year + 1900 + k
                month = month - 1 - k * 12

                local hour = (c & 1) << 4 | (d & 0xf000) >> 12
                local minute = (d & 0xfc0) >> 6
                local offset_sign = (d & 32) >> 5 -- 0 = +, i have no clue why
                local offset = d & 31 -- 2 = hour, meaning one means 30 minutes of offset

                local epoch = dateToEpoch(year, month, day) + (hour * 3600) + (minute * 60)
                local utc_year, utc_month, utc_day, utc_hour, utc_minute = epochToDate(epoch)
                local weekday_table = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"}
                time_display_utc = string.format("%d/%02d/%02d (%s) - %02d:%02d", utc_year, utc_month, utc_day, weekday_table[getDayOfWeek(utc_year, utc_month, utc_day)], utc_hour, utc_minute)

                time_display_offset = os.difftime(system_time, epoch+1735689600)

                if offset_sign == 0 then epoch = epoch + (offset*1800)
                else epoch = epoch - (offset*1800) end

                local local_year, local_month, local_day, local_hour, local_minute = epochToDate(epoch)
                time_display_local = string.format("%d/%02d/%02d (%s) - %02d:%02d", local_year, local_month, local_day, weekday_table[getDayOfWeek(local_year, local_month, local_day)], local_hour, local_minute)
            end
        end
    end
    render_menu()
end
render_menu()