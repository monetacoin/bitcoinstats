# encoding: utf-8

require 'zlib'
require 'date'
require 'fileutils'
require 'cgi'
require 'geoip'
require 'sqlite3'

Process.setpriority(Process::PRIO_PROCESS, 0, 19)

SCRIPTPATH = File.expand_path(File.dirname(__FILE__))
TEMPLATEPATH = SCRIPTPATH + '/static'
WEBSITENAME = 'Website name'
ACCEPTPAGE = '/([^ ?#]*/)?([^ ?#]*\.(html|pdf|asc|txt|exe|gz|dmg|zip|torrent|gpg|[0-9]+)|[^ ?#.]*)?([#?][^ ]*)?'
DBPATH = SCRIPTPATH + '/DB'
LOGSPATH = '/var/log/nginx'
WEBPATH = '/var/www/stats'
GEOIPPATH = "/usr/share/GeoIP/GeoIP.dat"
BOTLIMIT = 10000
DOSLIMIT = 100000

if !ARGV.empty? and ARGV[0] == 'replay'
	REPLAY = true
else
	REPLAY = false
end

$dbdata = {'pageviews' => {}, 'pages' => {}, 'countries' => {}, 'ips' => {}, 'blacklist' => {}}

$benchstart = Time.new.to_i

$countryname={
'AD'=>'Andorra',
'AE'=>'United Arab Emirates',
'AF'=>'Afghanistan',
'AG'=>'Antigua And Barbuda',
'AI'=>'Anguilla',
'AL'=>'Albania',
'AM'=>'Armenia',
'AO'=>'Angola',
'AR'=>'Argentina',
'AS'=>'American Samoa',
'AT'=>'Austria',
'AU'=>'Australia',
'AW'=>'Aruba',
'AX'=>'Åland Islands',
'AZ'=>'Azerbaijan',
'BA'=>'Bosnia And Herzegovina',
'BB'=>'Barbados',
'BD'=>'Bangladesh',
'BE'=>'Belgium',
'BF'=>'Burkina Faso',
'BG'=>'Bulgaria',
'BH'=>'Bahrain',
'BI'=>'Burundi',
'BJ'=>'Benin',
'BM'=>'Bermuda',
'BN'=>'Brunei Darussalam',
'BO'=>'Bolivia',
'BR'=>'Brazil',
'BS'=>'Bahamas',
'BT'=>'Bhutan',
'BV'=>'Bouvet Island',
'BW'=>'Botswana',
'BY'=>'Belarus',
'BZ'=>'Belize',
'CA'=>'Canada',
'CC'=>'Cocos (keeling) Islands',
'CD'=>'Congo, Republic',
'CF'=>'Central African Republic',
'CG'=>'Congo',
'CH'=>'Switzerland',
'CI'=>'Ivory Coast',
'CK'=>'Cook Islands',
'CL'=>'Chile',
'CM'=>'Cameroon',
'CN'=>'China',
'CO'=>'Colombia',
'CR'=>'Costa Rica',
'CU'=>'Cuba',
'CV'=>'Cape Verde',
'CX'=>'Christmas Island',
'CY'=>'Cyprus',
'CZ'=>'Czech Republic',
'DE'=>'Germany',
'DJ'=>'Djibouti',
'DK'=>'Denmark',
'DM'=>'Dominica',
'DO'=>'Dominican Republic',
'DZ'=>'Algeria',
'EC'=>'Ecuador',
'EE'=>'Estonia',
'EG'=>'Egypt',
'EH'=>'Western Sahara',
'ER'=>'Eritrea',
'ES'=>'Spain',
'ET'=>'Ethiopia',
'FI'=>'Finland',
'FJ'=>'Fiji',
'FK'=>'Falkland Islands (malvinas)',
'FM'=>'Micronesia, Federated States',
'FO'=>'Faroe Islands',
'FR'=>'France',
'GA'=>'Gabon',
'GB'=>'United Kingdom',
'GD'=>'Grenada',
'GE'=>'Georgia',
'GF'=>'French Guiana',
'GH'=>'Ghana',
'GI'=>'Gibraltar',
'GL'=>'Greenland',
'GM'=>'Gambia',
'GN'=>'Guinea',
'GP'=>'Guadeloupe',
'GQ'=>'Equatorial Guinea',
'GR'=>'Greece',
'GS'=>'South Georgia',
'GT'=>'Guatemala',
'GU'=>'Guam',
'GW'=>'Guinea-bissau',
'GY'=>'Guyana',
'HK'=>'Hong Kong',
'HM'=>'Heard Island And Mcdonald Islands',
'HN'=>'Honduras',
'HR'=>'Croatia',
'HT'=>'Haiti',
'HU'=>'Hungary',
'ID'=>'Indonesia',
'IE'=>'Ireland',
'IL'=>'Israel',
'IN'=>'India',
'IO'=>'Indian Ocean Territory',
'IQ'=>'Iraq',
'IR'=>'Iran, Islamic Republic',
'IS'=>'Iceland',
'IT'=>'Italy',
'JM'=>'Jamaica',
'JO'=>'Jordan',
'JP'=>'Japan',
'KE'=>'Kenya',
'KG'=>'Kyrgyzstan',
'KH'=>'Cambodia',
'KI'=>'Kiribati',
'KM'=>'Comoros',
'KN'=>'Saint Kitts And Nevis',
'KP'=>'Korea, North',
'KR'=>'Korea, South',
'KW'=>'Kuwait',
'KY'=>'Cayman Islands',
'KZ'=>'Kazakhstan',
'LA'=>'Lao Republic',
'LB'=>'Lebanon',
'LC'=>'Saint Lucia',
'LI'=>'Liechtenstein',
'LK'=>'Sri Lanka',
'LR'=>'Liberia',
'LS'=>'Lesotho',
'LT'=>'Lithuania',
'LU'=>'Luxembourg',
'LV'=>'Latvia',
'LY'=>'Libya',
'MA'=>'Morocco',
'MC'=>'Monaco',
'MD'=>'Moldova, Republic',
'ME'=>'Montenegro',
'MG'=>'Madagascar',
'MH'=>'Marshall Islands',
'MK'=>'Macedonia',
'ML'=>'Mali',
'MM'=>'Myanmar',
'MN'=>'Mongolia',
'MO'=>'Macao',
'MP'=>'Northern Mariana Islands',
'MQ'=>'Martinique',
'MR'=>'Mauritania',
'MS'=>'Montserrat',
'MT'=>'Malta',
'MU'=>'Mauritius',
'MV'=>'Maldives',
'MW'=>'Malawi',
'MX'=>'Mexico',
'MY'=>'Malaysia',
'MZ'=>'Mozambique',
'NA'=>'Namibia',
'NC'=>'New Caledonia',
'NE'=>'Niger',
'NF'=>'Norfolk Island',
'NG'=>'Nigeria',
'NI'=>'Nicaragua',
'NL'=>'Netherlands',
'NO'=>'Norway',
'NP'=>'Nepal',
'NR'=>'Nauru',
'NU'=>'Niue',
'NZ'=>'New Zealand',
'OM'=>'Oman',
'PA'=>'Panama',
'PE'=>'Peru',
'PF'=>'French Polynesia',
'PG'=>'Papua New Guinea',
'PH'=>'Philippines',
'PK'=>'Pakistan',
'PL'=>'Poland',
'PM'=>'Saint Pierre And Miquelon',
'PN'=>'Pitcairn',
'PR'=>'Puerto Rico',
'PS'=>'Palestinian Territory, Occupied',
'PT'=>'Portugal',
'PW'=>'Palau',
'PY'=>'Paraguay',
'QA'=>'Qatar',
'RE'=>'Réunion',
'RO'=>'Romania',
'RS'=>'Serbia',
'RU'=>'Russian Federation',
'RW'=>'Rwanda',
'SA'=>'Saudi Arabia',
'SB'=>'Solomon Islands',
'SC'=>'Seychelles',
'SD'=>'Sudan',
'SE'=>'Sweden',
'SG'=>'Singapore',
'SH'=>'Saint Helena',
'SI'=>'Slovenia',
'SJ'=>'Svalbard And Jan Mayen',
'SK'=>'Slovakia',
'SL'=>'Sierra Leone',
'SM'=>'San Marino',
'SN'=>'Senegal',
'SO'=>'Somalia',
'SR'=>'Suriname',
'ST'=>'Sao Tome And Principe',
'SV'=>'El Salvador',
'SY'=>'Syrian Arab Republic',
'SZ'=>'Swaziland',
'TC'=>'Turks And Caicos Islands',
'TD'=>'Chad',
'TF'=>'French Southern Territories',
'TG'=>'Togo',
'TH'=>'Thailand',
'TJ'=>'Tajikistan',
'TK'=>'Tokelau',
'TL'=>'Timor-leste',
'TM'=>'Turkmenistan',
'TN'=>'Tunisia',
'TO'=>'Tonga',
'TR'=>'Turkey',
'TT'=>'Trinidad And Tobago',
'TV'=>'Tuvalu',
'TW'=>'Taiwan, Province Of China',
'TZ'=>'Tanzania, United Republic',
'UA'=>'Ukraine',
'UG'=>'Uganda',
'UM'=>'Minor Outlying Islands',
'US'=>'United States',
'UY'=>'Uruguay',
'UZ'=>'Uzbekistan',
'VA'=>'Holy See (vatican)',
'VC'=>'Saint Vincent And The Grenadines',
'VE'=>'Venezuela',
'VG'=>'Virgin Islands, British',
'VI'=>'Virgin Islands, U.s.',
'VN'=>'Viet Nam',
'VU'=>'Vanuatu',
'WF'=>'Wallis And Futuna',
'WS'=>'Samoa',
'YE'=>'Yemen',
'YT'=>'Mayotte',
'ZA'=>'South Africa',
'ZM'=>'Zambia',
'ZW'=>'Zimbabwe',
'--'=>'Unknown',
}


# Return split array from log line.
def splitLine(data)

	dataar = []

	while !data.nil? and data.length > 0 do

		case data[0, 1]
		when '"'
			dataar.push(data[1..data.index('"', 1)-1])
			data = data[data.index('"', 1)+2..data.length]
		when '['
			dataar.push(data[1..data.index(']')-1])
			data = data[data.index(']')+2..data.length]
		else
			dataar.push(data[0..data.index(' ')-1])
			data = data[data.index(' ')+1..data.length]
		end
	end

	return dataar

end


# Return extracted data from log line.
def parseLine(data)

	data = splitLine(data)

	page = data[4][data[4].index(' ')+1..data[4].rindex(' ')-1]
	page = page[0..page.index('?')-1] if !page.index('?').nil?
	page = page[0..page.index('#')-1] if !page.index('#').nil?
	page = page.gsub(/\\x[a-f0-9]{2}/i){|m| m[2..-1].to_i(16).chr} if !page.index('\\x').nil?
	page = page.gsub(/\/+/,'/') if !page.index('//').nil?
	page = CGI.unescape(page)

	datedata = data[3][0..data[3].index(':')-1].split('/')
	timedata = data[3][data[3].index(':')+1..data[3].index(' ')-1].split(':')
	timezone = data[3][data[3].index(' ')+1,3] + ':' + data[3][data[3].index(' ')+4,2]
	time = Time.new(datedata[2].to_i, Date::ABBR_MONTHNAMES.index(datedata[1]), datedata[0].to_i, timedata[0].to_i, timedata[1].to_i, timedata[2].to_i, timezone)
	time.utc
	timei = time.to_i

	ar = {}
	ar['time'] = timei
	ar['year'] = time.year
	ar['month'] = time.month
	ar['day'] = time.day
	ar['page'] = page
	ar['IP'] = data[0]
	ar['country'] = $geoip.country(data[0]).country_code2
	ar['referer'] = data[7]
	ar['useragent'] = data[8]

	return ar

end


# Return log line with anonymized IP.
def anonymizeLine(data)

	dot = data.index('.')
	dot = data.index('.', dot+1)
	dot = data.index('.', dot+1)

	return data[0..dot] + '0' + data[data.index(' ', dot+1)..data.length]

end


# Return number of days in a month.
def calendardays(y, m)

	return 29 if m == 2 && Date.gregorian_leap?(y)
	return [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m]

end


# Return number in readable format.
def formatnumber(number)

	return number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse

end


# Get first line from log number.
def getFirstLine(n, replay=REPLAY)

	path = LOGSPATH
	path = DBPATH + '/logs' if replay == true

	firstline = ''
	ex = ''
	ex = '.' + n.to_s if n > 0
	begin
		if File.exist?(path + '/access.log' + ex)
			log = File.new(path + '/access.log' + ex,'r')
		elsif File.exist?(path + '/access.log' + ex + '.gz')
			loggz = File.new(path + '/access.log' + ex + '.gz','r')
			log = Zlib::GzipReader.new(loggz)
		end
		log.each do |line|
			firstline = line
			break
		end
	ensure
		log.close if !log.closed?
		loggz.close if !(defined?(loggz)).nil? and !loggz.nil? and !loggz.closed?
	end

	return firstline

end


# Get last line from log number.
def getLastLine(n, replay=REPLAY)

	path = LOGSPATH
	path = DBPATH + '/logs' if replay == true

	lastline = ''
	ex = ''
	ex = '.' + n.to_s if n > 0
	# Use seek if file is not compressed.
	if File.exist?(path + '/access.log' + ex)
		begin
			log = File.new(path + '/access.log' + ex,'r')
			buffer = 0
			while lastline.scan("\n").length < 2 do
				buffer -= 1024
				log.seek(buffer, IO::SEEK_END)
				lastline = log.read()
			end
			lastline = lastline.split("\n")
			if lastline[lastline.length-1].length > 0
				lastline = lastline[lastline.length-1]
			else
				lastline = lastline[lastline.length-2]
			end
		ensure
			log.close if !log.closed?
		end
	# Loop if file is compressed.
	elsif File.exist?(path + '/access.log' + ex + '.gz')
		begin
			loggz = File.new(path + '/access.log' + ex + '.gz','r')
			log = Zlib::GzipReader.new(loggz)
			log.each do |line|
				lastline = line
			end
		ensure
			log.close if !log.closed?
			loggz.close if !loggz.nil? and !loggz.closed?
		end
	end

	return lastline

end


# Abord script with error message.
def abord(msg)

	print msg + "\n"
	exit

end


# Print benchmark data on screen.
def printbenchmark(start, count)

	diff = Time.new.to_i - start
	print formatnumber(count) + ' lines processed in ' + formatnumber(diff) + ' seconds - ' + formatnumber(count / [diff, 1].max) + ' lines per second.'  + "\n"

end


# Set global variables for start and stop time, year, month, day.
def setStartStopTime(start, stop)

	# Set start and stop time.
	$starttime = start
	$stoptime = stop

	# Avoid importing data after DB stop time, or before DB start time.
	$stoptime = $stoptime <= $dbstoptime ? $stoptime : $dbstoptime
	$starttime = $starttime > $dbstarttime ? $starttime : $dbstarttime

	# Set start and stop year, month, day.
	t = Time.at([$starttime, $stoptime].min)
	t.utc
	$ys = t.year
	$ms = t.month
	$ds = t.day
	t = Time.at([$starttime-1, $stoptime-1].max)
	t.utc
	$ye = t.year
	$me = t.month
	$de = t.day

	# Set intervals for database.
	$intms = (sprintf('%04d', $ys) + sprintf('%02d', $ms) + '00').to_i
	$intme = (sprintf('%04d', $ye) + sprintf('%02d', $me) + '00').to_i
	$intds = (sprintf('%04d', $ys) + sprintf('%02d', $ms) + sprintf('%02d', $ds)).to_i
	$intde = (sprintf('%04d', $ye) + sprintf('%02d', $me) + sprintf('%02d', $de)).to_i

end


# Find start log based on start time.
def setStartLog(replay=REPLAY)

	path = LOGSPATH
	path = DBPATH + '/logs' if replay == true

	$startlog = 0
	while File.exist?(path + '/access.log.' + ($startlog+1).to_s) or File.exist?(path + '/access.log.' + ($startlog+1).to_s + '.gz') do
		firstline = parseLine(getFirstLine($startlog, replay))
		break if firstline['time'] < $starttime
		$startlog += 1
	end

end


# Find stop log based on stop time.
def setStopLog(replay=REPLAY)

	path = LOGSPATH
	path = DBPATH + '/logs' if replay == true

	$stoplog = 0
	while File.exist?(path + '/access.log.' + ($stoplog+1).to_s) or File.exist?(path + '/access.log.' + ($stoplog+1).to_s + '.gz') do
		firstline = parseLine(getFirstLine($stoplog, replay))
		break if firstline['time'] < $stoptime
		$stoplog += 1
	end

end


# Check if working paths and files are missing, create them if needed.
def checkEnvironment

	# Abord if important paths or files are missing.
	abord(LOGSPATH + ' is missing') if !File.directory?(LOGSPATH)
	abord(LOGSPATH + '/access.log is missing') if (!File.file?(LOGSPATH + '/access.log') and !File.file?(LOGSPATH + '/access.log.gz'))
	abord(GEOIPPATH + ' is missing') if !File.file?(GEOIPPATH)
	abord(TEMPLATEPATH + '/main.css is missing') if !File.file?(TEMPLATEPATH + '/main.css')
	abord(TEMPLATEPATH + '/main.js is missing') if !File.file?(TEMPLATEPATH + '/main.js')
	abord(DBPATH + '/logs/access.log.gz is missing') if !File.exist?(DBPATH + '/logs/access.log.gz') and Dir[DBPATH + '/*'].length > 0
	abord(DBPATH + '/DB.db is missing') if !File.exist?(DBPATH + '/DB.db') and Dir[DBPATH + '/*'].length > 0 and REPLAY == false
	abord(DBPATH + '/lock seems to indicate concurrent database access or corrupted database. You should make sure the script is not running, delete the lock file, and run the script with the replay argument.') if File.exist?(DBPATH + '/lock')

	# Create directories if not exist.
	FileUtils.mkdir_p(WEBPATH) if !File.directory?(WEBPATH)
	FileUtils.mkdir_p(DBPATH) if !File.directory?(DBPATH)
	FileUtils.mkdir_p(DBPATH + '/logs') if !File.directory?(DBPATH + '/logs')

	# Backup old database if in replay mode.
	if REPLAY == true and File.exist?(DBPATH + '/DB.db')
		t = Time.new
		date = sprintf('%04d', t.year) + '-' + sprintf('%02d', t.month) + '-' + sprintf('%02d', t.day)
		n = 0
		ex = ''
		while File.exist?(DBPATH + '/DB-' + date + ex + '.db') do
			n += 1
			ex = '-' + sprintf('%03d', n)
		end
		File.rename(DBPATH + '/DB.db',DBPATH + '/DB-' + date + ex + '.db')
	end

	# Create or load database.
	if !File.exist?(DBPATH + '/DB.db')
		$db = SQLite3::Database.new DBPATH + '/DB.db'
		$db.execute 'CREATE TABLE IF NOT EXISTS `pageviews`(`id` TEXT UNIQUE, `year` INTEGER, `month` INTEGER, `day` INTEGER, `count` INTEGER)'
		$db.execute 'CREATE TABLE IF NOT EXISTS `pages`(`id` TEXT UNIQUE, `year` INTEGER, `month` INTEGER, `page` TEXT, `count` INTEGER)'
		$db.execute 'CREATE TABLE IF NOT EXISTS `visitors`(`id` TEXT UNIQUE, `year` INTEGER, `month` INTEGER)'
		$db.execute 'CREATE TABLE IF NOT EXISTS `countries`(`id` TEXT UNIQUE, `year` INTEGER, `month` INTEGER, `country` TEXT, `count` INTEGER)'
		$db.execute 'CREATE TABLE IF NOT EXISTS `blacklist`(`id` TEXT UNIQUE, `year` INTEGER, `month` INTEGER, `day` INTEGER, `ip` TEXT)'
		$db.execute 'CREATE TABLE IF NOT EXISTS `config`(`id` TEXT UNIQUE, `data` TEXT)'
	else
		$db = SQLite3::Database.open DBPATH + '/DB.db'
	end

	# Create temporary database.
	File.delete(DBPATH + '/tmp.db') if File.exist?(DBPATH + '/tmp.db')
	$tmpdb = SQLite3::Database.new DBPATH + '/tmp.db'
	$tmpdb.execute 'CREATE TABLE IF NOT EXISTS `ips`(`id` TEXT UNIQUE, `year` INTEGER, `month` INTEGER, `day` INTEGER, `ip` TEXT, `count` INTEGER)'
	$tmpdb.execute 'PRAGMA synchronous = 0'

	# Create GEOIP object.
	$geoip = GeoIP.new(GEOIPPATH)

end


# Find start time, stop time and start log file.
def checkStartPoint

	path = LOGSPATH
	path = DBPATH + '/logs' if REPLAY == true

	# On first start or replay mode, set start time and log from first line of last log file.
	if !File.exist?(DBPATH + '/logs/access.log.gz') or REPLAY == true
		$startlog = 0
		$startlog += 1 while File.exist?(path + '/access.log.' + ($startlog+1).to_s) or File.exist?(path + '/access.log.' + ($startlog+1).to_s + '.gz')
		firstline = parseLine(getFirstLine($startlog))
		$starttime = Time.new(firstline['year'], firstline['month'], firstline['day'], 0, 0, 0, "+00:00").to_i
	# If DB exists, set start time and log from last stop time on DB.
	else
		$starttime = 0
		s = $db.prepare 'SELECT `data` FROM `config` WHERE `id` = \'resume\''
		r = s.execute
		r.each do |row|
			$starttime = row[0].to_i
		end
		s.close
		abord(DBPATH + ' must be restarted using saved server logs.') if $starttime == 0
		setStartLog()
	end

	# Set DB start time.
	$dbstarttime = $starttime
	s = $db.prepare 'SELECT `year`, `month`, `day` FROM `pageviews` ORDER BY `year` ASC, `month` ASC, `day` ASC LIMIT 1'
	r = s.execute
	r.each do |row|
		$dbstarttime = Time.new(row[0], row[1], row[2], 0, 0, 0, "+00:00").to_i
	end
	s.close

	# Set stop time from last line of first log file.
	lastline = parseLine(getLastLine(0))
	$stoptime = $dbstoptime = Time.new(lastline['year'], lastline['month'], lastline['day'], 0, 0, 0, "+00:00").to_i
	$stoptime = $dbstoptime = lastline['time'] + 1 if REPLAY == true
	$stoptime = $dbstoptime = $starttime if $dbstoptime < $starttime
	$stoplog = 0

	setStartStopTime($starttime, $stoptime)

end


# Reset and load saved stats data between start and stop time.
def loadStats(replay=REPLAY)

	# Pre-initialize database variables from start to stop day.
	($ys..$ye).each do |yi|
		msi = ($ys == yi) ? $ms : 1
		mei = ($ye == yi) ? $me : 12
		$dbdata['pages'][yi] = {} if !$dbdata['pages'].has_key?(yi)
		$dbdata['countries'][yi] = {} if !$dbdata['countries'].has_key?(yi)
		$dbdata['blacklist'][yi] = {} if !$dbdata['blacklist'].has_key?(yi)
		$dbdata['pageviews'][yi] = {} if !$dbdata['pageviews'].has_key?(yi)
		$dbdata['ips'][yi] = {} if !$dbdata['ips'].has_key?(yi)
		(msi..mei).each do |mi|
			dsi = ($ys == yi and $ms == mi) ? $ds : 1
			dei = ($ye == yi and $me == mi) ? $de : calendardays(yi, mi)
			$dbdata['pages'][yi][mi] = {}
			$dbdata['countries'][yi][mi] = {}
			$dbdata['blacklist'][yi][mi] = {} if !$dbdata['blacklist'][yi].has_key?(mi)
			$dbdata['pageviews'][yi][mi] = {} if !$dbdata['pageviews'][yi].has_key?(mi)
			$dbdata['ips'][yi][mi] = {} if !$dbdata['ips'][yi].has_key?(mi)
			(dsi..dei).each do |di|
				$dbdata['blacklist'][yi][mi][di] = {}
				$dbdata['pageviews'][yi][mi][di] = 0
				$dbdata['ips'][yi][mi][di] = {}
			end
		end
	end

	# Import blacklist data from database.
	s = $db.prepare 'SELECT `year`, `month`, `day`, `ip` FROM `blacklist` WHERE `year` * 10000 + `month` * 100 + `day` BETWEEN ? AND ?'
	s.bind_params($intds, $intde)
	r = s.execute
	r.each do |row|
		$dbdata['blacklist'][row[0]][row[1]][row[2]][row[3]] = 1
	end
	s.close

	# Clean ips database if in replay mode.
	if replay == true
		s = $tmpdb.prepare 'DELETE FROM `ips` WHERE `year` * 10000 + `month` * 100 BETWEEN ? AND ?'
		s.bind_params($intms, $intme)
		s.execute
		s.close
	end

	# Import stats data from database to variables only if not in replay mode.
	if replay == false
		s = $db.prepare 'SELECT `year`, `month`, `page`, `count` FROM `pages` WHERE `year` * 10000 + `month` * 100 BETWEEN ? AND ?'
		s.bind_params($intms, $intme)
		r = s.execute
		r.each do |row|
			$dbdata['pages'][row[0]][row[1]][row[2]] = row[3]
		end
		s.close
		s = $db.prepare 'SELECT `year`, `month`, `country`, `count` FROM `countries` WHERE `year` * 10000 + `month` * 100 BETWEEN ? AND ?'
		s.bind_params($intms, $intme)
		r = s.execute
		r.each do |row|
			$dbdata['countries'][row[0]][row[1]][row[2]] = row[3]
		end
		s.close
		s = $db.prepare 'SELECT `year`, `month`, `day`, `count` FROM `pageviews` WHERE `year` * 10000 + `month` * 100 + `day` BETWEEN ? AND ?'
		s.bind_params($intds, $intde)
		r = s.execute
		r.each do |row|
			$dbdata['pageviews'][row[0]][row[1]][row[2]] = row[3]
		end
		s.close
		s = $db.prepare 'SELECT `id`, `year`, `month` FROM `visitors` WHERE `year` * 10000 + `month` * 100 BETWEEN ? AND ?'
		s.bind_params($intms, $intme)
		r = s.execute
		r.each do |row|
			ip = row[0][row[0].rindex('-')+1..row[0].length]
			ss = $tmpdb.prepare 'INSERT OR IGNORE INTO `ips` (`id`, `year`, `month`, `day`, `ip`, `count`) VALUES (?, ?, ?, 0, ?, 1)'
			ss.bind_params(row[0], row[1], row[2], ip)
			ss.execute
			ss.close
		end
		s.close
	end

end


# Import data from start log to stop log.
def importData(replay=REPLAY)

	benchstart = Time.new.to_i
	linecount = 0
	logregex = Regexp.new('^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} [^ ]+ [^ ]+ \[[a-zA-Z0-9:+\-/ ]+\] "GET ' + ACCEPTPAGE + ' [A-Za-z0-9/.]+" (200|304) [0-9]+ "[^"]*" "[^"]*"')
	lognum = $startlog

	begin
		if replay == false
			tmploggz = File.open(DBPATH + '/logs/tmp.log.gz', 'w')
			tmplog = Zlib::GzipWriter.wrap(tmploggz)
			path = LOGSPATH
		else
			tmplog = File.open(File::NULL, "w")
			path = DBPATH + '/logs'
		end
		while lognum >= $stoplog do
			app = ''
			app = '.' + lognum.to_s if lognum > 0
			begin
				if File.exist?(path + '/access.log' + app)
					file = File.new(path + '/access.log' + app,'r')
				elsif File.exist?(path + '/access.log' + app + '.gz')
					filegz = File.new(path + '/access.log' + app + '.gz','r')
					file = Zlib::GzipReader.new(filegz)
				end
				file.grep(logregex) do |line|
					linecount += 1
					if linecount % 10000 == 0
						printbenchmark(benchstart, linecount)
						saveIPCache()
					end
					line = anonymizeLine(line) if replay == false
					data = parseLine(line)
					next if data['time'] >= $stoptime or data['time'] < $starttime
					tmplog.puts line
					updateStats(data)
				end

			ensure
				file.close if !file.closed?
				filegz.close if !(defined?(filegz)).nil? and !filegz.nil? and !filegz.closed?
			end
			lognum -=1
		end
	ensure
		tmplog.close if !tmplog.closed?
		tmploggz.close if !tmploggz.nil? and !tmploggz.closed?
	end

end


# Check if given array of IPs on given days seem like bots.
def checkBots(list)

	# Set start and stop times, and unique page, referer and useragent count and hash.
	list.each_index do |k|
		list[k]['starttime'] = Time.new(list[k]['y'], list[k]['m'], list[k]['d'], 0, 0, 0, "+00:00").to_i
		list[k]['stoptime'] = Time.new(list[k]['y'], list[k]['m'], list[k]['d'], 23, 59, 59, "+00:00").to_i
		list[k]['p'] = []
		list[k]['pc'] = 0
		list[k]['r'] = []
		list[k]['rc'] = 0
		list[k]['u'] = []
		list[k]['uc'] = 0
	end

	# Set IPs to match in regular expression.
	ips = {}
	list.each do |data|
		ips[data['i']] = 1
	end
	ips = '(' + ips.keys.join('|').gsub('.','\\.') + ')'

	# Set start and stop time.
	starttime = list.min_by {|x| x['startime'] }['starttime']
	stoptime = list.max_by {|x| x['stoptime'] }['stoptime']
	setStartStopTime(starttime, stoptime)

	# Set start and stop log.
	setStartLog(true)
	setStopLog(true)

	# Assign variables.
	benchstart = Time.new.to_i
	linecount = 0
	logregex = Regexp.new('^' + ips + ' [^ ]+ [^ ]+ \[[a-zA-Z0-9:+\-/ ]+\] "GET ' + ACCEPTPAGE + ' [A-Za-z0-9/.]+" (200|304) [0-9]+ "[^"]+" "[^"]+"')
	lognum = $startlog
	path = DBPATH + '/logs'

	# Search lines with given IP.
	print "\n" + 'Checking suspect page requests' + "\n"
	while lognum >= $stoplog do
		app = ''
		app = '.' + lognum.to_s if lognum > 0
		begin

			if File.exist?(path + '/access.log' + app)
				file = File.new(path + '/access.log' + app,'r')
			elsif File.exist?(path + '/access.log' + app + '.gz')
				filegz = File.new(path + '/access.log' + app + '.gz','r')
				file = Zlib::GzipReader.new(filegz)
			end
			file.grep(logregex) do |line|

				# Assign variables
				linecount += 1
				printbenchmark(benchstart, linecount) if ( linecount % 10000 == 0 )
				line = parseLine(line)

				# Update page, referer, useragent counts.
				list.each_index do |k|
					next if list[k]['i'] != line['IP']
					next if line['time'] > list[k]['stoptime'] or line['time'] < list[k]['starttime']
					if list[k]['pc'] < 10 and !list[k]['p'].include?(line['page'])
						list[k]['pc'] += 1
						list[k]['p'].push(line['page'])
					end
					if list[k]['rc'] < 10 and !list[k]['r'].include?(line['referer'])
						list[k]['rc'] += 1
						list[k]['r'].push(line['referer'])
					end
					if list[k]['uc'] < 10 and !list[k]['u'].include?(line['useragent'])
						list[k]['uc'] += 1
						list[k]['u'].push(line['useragent'])
					end
				end

				# Delete entries from the list when enough unique pages, referers and useragents are found.
				list.delete_if {|data| data['pc'] >= 10 and data['rc'] >= 10 and data['uc'] >= 10}

			end

		ensure
			file.close if !file.closed?
			filegz.close if !(defined?(filegz)).nil? and !filegz.nil? and !filegz.closed?
		end
		lognum -=1
	end

	# Return filtered list of bots.
	return list

end


# Filter requests from IPs with an unusual number of requests by day.
def filterBots

	# Set hash for months that will need to be re-processed with the black list.
	replay = {}
	suspects = []
	blacklist = []

	# Loop through IPs with page request count above defined limits.
	s = $tmpdb.prepare 'SELECT `year`, `month`, `day`, `ip`, `count` FROM `ips` WHERE `count` >= ' + BOTLIMIT.to_s + ' OR `count` >= ' + DOSLIMIT.to_s
	r = s.execute
	r.each do |row|

		# Set variables.
		y = row[0]
		m = row[1]
		d = row[2]
		i = row[3]
		n = row[4]

		# Do nothing if the IP is already blacklisted.
		blacklisted = false
		ss = $db.prepare 'SELECT COUNT(`id`) FROM `blacklist` WHERE `id` = ?'
		ss.bind_params(sprintf('%04d', y) + '-' + sprintf('%02d', m) + '-' + sprintf('%02d', d) + '-' + i)
		rr = ss.execute
		rr.each do |row|
			blacklisted = true if row[0] > 0
		end
		ss.close
		next if blacklisted == true

		# Add IP to appropriate list depending on the traffic being considered as a DoS or potential bot.
		if n >= DOSLIMIT
			blacklist.push({'y' => y, 'm' => m, 'd' => d, 'i' => i})
		else
			suspects.push({'y' => y, 'm' => m, 'd' => d, 'i' => i})
		end

	end
	s.close

	# Check if suspected IPs are bots and add them to the blacklist if so.
	if suspects.length > 0
		checkBots(suspects).each do |data|
			blacklist.push({'y' => data['y'], 'm' => data['m'], 'd' => data['d'], 'i' => data['i']})
		end
	end

	# Blacklist IPs and set months to be re-processed.
	blacklist.each do |data|

		# Set variables.
		y = data['y']
		m = data['m']
		d = data['d']
		i = data['i']

		# Blacklist the IP for the given month.
		s = $db.prepare 'INSERT OR IGNORE INTO `blacklist` (`id`, `year`, `month`, `day`, `ip`) VALUES (?, ?, ?, ?, ?)'
		s.bind_params(sprintf('%04d', y) + '-' + sprintf('%02d', m) + '-' + sprintf('%02d', d) + '-' + i, y, m, d, i)
		s.execute
		s.close

		# Add months to be re-processed with the updated blacklist.
		replay[y] = {} if !replay.has_key?(y)
		replay[y][m] = 1

	end

	# Reset and reimport data for each months with newly blacklisted IPs.
	replay.each do |y, val|
	replay[y].each do |m, val|

		# Set end date.
		ye = y
		me = m + 1
		if me > 12
			ye += 1
			me = 1
		end

		# Set start and stop time.
		starttime = Time.new(y, m, 1, 0, 0, 0, "+00:00").to_i
		stoptime = Time.new(ye, me, 1, 0, 0, 0, "+00:00").to_i
		setStartStopTime(starttime, stoptime)

		# Set start and stop log.
		setStartLog(true)
		setStopLog(true)

		# Reset and reload stats for the given period.
		loadStats(true)

		print "\n" + 'Reprocessing data for ' + sprintf('%04d', y) + '-' + sprintf('%02d', m) + "\n"

		# Re-import data from the logs without updating tmp.log.gz.
		importData(true)

	end
	end

	# Re-save stats
	saveStats()

end


# Delete remaining temporary files.
def cleanEnvironment

	$tmpdb.close
	File.delete(DBPATH + '/tmp.db')

end


# Update stats count.
def updateStats(data)

	# Set variables.
	y = data['year']
	m = data['month']
	d = data['day']
	p = data['page']
	c = data['country']
	i = data['IP']

	# Ignore lines with blacklisted IP.
	return if $dbdata['blacklist'][y][m][d].has_key?(i)

	# Update pageviews by IP, later used for bots detection and unique visitors count.
	if !$dbdata['ips'][y][m][d].has_key?(i)
		$dbdata['ips'][y][m][d][i] = 1
	else
		$dbdata['ips'][y][m][d][i] += 1
	end

	# Update pageviews count.
	$dbdata['pageviews'][y][m][d] += 1

	# Update pageviews by page requested count.
	if !$dbdata['pages'][y][m].has_key?(p)
		$dbdata['pages'][y][m][p] = 1
	else
		$dbdata['pages'][y][m][p] += 1
	end

	# Update pageviews by country count.
	if !$dbdata['countries'][y][m].has_key?(c)
		$dbdata['countries'][y][m][c] = 1
	else
		$dbdata['countries'][y][m][c] += 1
	end

end


# Update temporary IP database with data in memory.
def saveIPCache

	$dbdata['ips'].each do |y, val|
		$dbdata['ips'][y].each do |m, val|
			$dbdata['ips'][y][m].each do |d, val|
				$dbdata['ips'][y][m][d].each do |i, count|
					id = sprintf('%04d', y) + '-' + sprintf('%02d', m) + '-' + sprintf('%02d', d) + '-' + i
					s = $tmpdb.prepare 'INSERT OR IGNORE INTO `ips` (`id`, `year`, `month`, `day`, `ip`, `count`) VALUES (?, ?, ?, ?, ?, 0)'
					s.bind_params(id, y, m, d, i)
					s.execute
					s.close
					s = $tmpdb.prepare 'UPDATE `ips` SET `count` = `count` + ? WHERE `id` = ?'
					s.bind_params(count, id)
					s.execute
					s.close
				end
				$dbdata['ips'][y][m][d] = {}
			end
		end
	end

end


# Rotate saved logs.
def rotateLogs

	n = 0
	n += 1 while File.exist?(DBPATH + '/logs/access.log.' + (n+1).to_s + '.gz')

	while n >= 0 do
		ex = ''
		ex = '.' + n.to_s if n > 0
		File.rename(DBPATH + '/logs/access.log' + ex + '.gz', DBPATH + '/logs/access.log.' + (n+1).to_s + '.gz')
		n -= 1
	end

end


# Write stats data to file.
def saveStats

	# Create lock file.
	abord(DBPATH + '/lock seems to indicate concurrent database access or corrupted database. You should make sure the script is not running, delete the lock file, and run the script with the replay argument.') if File.exist?(DBPATH + '/lock')
	File.open(DBPATH + '/lock', 'w') {}

	# Save imported logs.
	if File.exist?(DBPATH + '/logs/tmp.log.gz')
		File.open(DBPATH + '/logs/tmp.log.gz', 'r') do |srcgz|
		Zlib::GzipReader.wrap(srcgz) do |src|

			begin

				# Temporary move access.log.gz to tmp.access.log.gz if file exists.
				File.delete(DBPATH + '/logs/tmp.access.log.gz') if File.exist?(DBPATH + '/logs/tmp.access.log.gz')
				File.rename(DBPATH + '/logs/access.log.gz', DBPATH + '/logs/tmp.access.log.gz') if File.exist?(DBPATH + '/logs/access.log.gz')

				# Create access.log.gz.
				dstgz = File.open(DBPATH + '/logs/access.log.gz', 'w')
				dst = Zlib::GzipWriter.wrap(dstgz)

				# Copy tmp.access.log.gz into access.log.gz
				# This is a workaround for GzipReader being unable to read data appended with GzipWriter to an existing file.
				if File.exist?(DBPATH + '/logs/tmp.access.log.gz')
					File.open(DBPATH + '/logs/tmp.access.log.gz', 'r') do |psrcgz|
					Zlib::GzipReader.wrap(psrcgz) do |psrc|
					psrc.each do |line|
						dst.puts line
					end
					end
					end
					File.delete(DBPATH + '/logs/tmp.access.log.gz')
				end

				# Save new imported lines.
				src.each do |line|
					dst.puts line
					# Rotate logs when file size gets bigger than 100Mb.
					if File.size(DBPATH + '/logs/access.log.gz') >= 100000000
						dst.close if !dst.closed?
						dstgz.close if !dstgz.nil? and !dstgz.closed?
						rotateLogs()
						dstgz = File.open(DBPATH + '/logs/access.log.gz', 'a')
						dst = Zlib::GzipWriter.wrap(dstgz)
					end
				end
			ensure
				dst.close if !dst.closed?
				dstgz.close if !dstgz.nil? and !dstgz.closed?
			end

		end
		end
		# Delete temporary log file.
		File.delete(DBPATH + '/logs/tmp.log.gz')
	end

	$db.execute 'BEGIN'

	# Update database with data in memory.
	$dbdata['pageviews'].each do |y, v|
		$dbdata['pageviews'][y].each do |m, v|
			$dbdata['pageviews'][y][m].each do |d, data|
				s = $db.prepare 'INSERT OR REPLACE INTO `pageviews` (`id`, `year`, `month`, `day`, `count`) VALUES (?, ?, ?, ?, ?)'
				s.bind_params(sprintf('%04d', y) + '-' + sprintf('%02d', m) + '-' + sprintf('%02d', d), y, m, d, data)
				s.execute
				s.close
			end
		end
	end
	$dbdata['countries'].each do |y, v|
		$dbdata['countries'][y].each do |m, v|
			$dbdata['countries'][y][m].each do |c, data|
				s = $db.prepare 'INSERT OR REPLACE INTO `countries` (`id`, `year`, `month`, `country`, `count`) VALUES (?, ?, ?, ?, ?)'
				s.bind_params(sprintf('%04d', y) + '-' + sprintf('%02d', m) + '-' + c, y, m, c, data)
				s.execute
				s.close
			end
		end
	end
	$dbdata['pages'].each do |y, v|
		$dbdata['pages'][y].each do |m, v|
			$dbdata['pages'][y][m].each do |p, data|
				s = $db.prepare 'INSERT OR REPLACE INTO `pages` (`id`, `year`, `month`, `page`, `count`) VALUES (?, ?, ?, ?, ?)'
				s.bind_params(sprintf('%04d', y) + '-' + sprintf('%02d', m) + '-' + p, y, m, p, data)
				s.execute
				s.close
			end
		end
	end

	# Update visitors database with data in temporary database.
	saveIPCache()

	s = $db.prepare 'DELETE FROM `visitors` WHERE `year` * 10000 + `month` * 100 BETWEEN ? AND ?'
	s.bind_params($intms, $intme)
	s.execute
	s.close

	s = $tmpdb.prepare 'SELECT `ip`, `year`, `month` FROM `ips`'
	r = s.execute
	r.each do |row|
		ss = $db.prepare 'INSERT OR IGNORE INTO `visitors` (`id`, `year`, `month`) VALUES (?, ?, ?)'
		ss.bind_params(sprintf('%04d', row[1]) + '-' + sprintf('%02d', row[2]) + '-' + row[0], row[1], row[2])
		ss.execute
		ss.close
	end
	s.close

	# Save resumetime to database to resume the script later.
	s = $db.prepare 'INSERT OR REPLACE INTO `config` (`id`, `data`) VALUES (\'resume\', ?)'
	s.bind_params($dbstoptime.to_s)
	s.execute
	s.close

	$db.execute 'COMMIT'

	# Delete lock file.
	File.delete(DBPATH + '/lock')

end


# Generate all HTML pages from stats.
def generatePages

	# Copy template javascript and CSS files.
	FileUtils.cp(TEMPLATEPATH + '/main.css', WEBPATH + '/main.css')
	FileUtils.cp(TEMPLATEPATH + '/main.js', WEBPATH + '/main.js')

	# Set start and stop dates for all available data.
	$ays = 1
	$ams = 1
	$aye = 0
	$ame = 0
	s = $db.prepare 'SELECT `year`, `month`, `day` FROM `pageviews` ORDER BY `year` ASC, `month` ASC, `day` ASC LIMIT 1'
	r = s.execute
	r.each do |row|
		$ays = row[0]
		$ams = row[1]
		$ads = row[2]
	end
	s.close
	s = $db.prepare 'SELECT `year`, `month`, `day` FROM `pageviews` ORDER BY `year` DESC, `month` DESC, `day` DESC LIMIT 1'
	r = s.execute
	r.each do |row|
		$aye = row[0]
		$ame = row[1]
		$ade = row[2]
	end

	# Generate index, yearly and monthly pages.
	generatePage()
	($ays..$aye).each do |yi|
		generatePage(yi)
		msi = ($ays == yi) ? $ams : 1
		mei = ($aye == yi) ? $ame : 12
		(msi..mei).each do |mi|
			generatePage(yi, mi)
		end
	end

	# Print benchmark data on screen.
	diff = ((Time.new.to_f - $benchstart) / 60).round
	print 'Logs processed in ' + formatnumber(diff) + ' minutes.'  + "\n"

end


# Generate HTML page from stats for given period.
def generatePage(y=nil, m=nil)

	# Set file name and title.
	id = 'index'
	name = 'All data'
	id = name = sprintf('%04d', y) if !y.nil?
	id = name += '-' + sprintf('%02d', m) if !m.nil?

	# Get pageviews for given period.
	pageviews = 0
	if (y.nil?)
		s = $db.prepare 'SELECT SUM(`count`) FROM `pageviews`'
	elsif (m.nil?)
		s = $db.prepare 'SELECT SUM(`count`) FROM `pageviews` WHERE `year` = ?'
		s.bind_params(y)
	else
		s = $db.prepare 'SELECT SUM(`count`) FROM `pageviews` WHERE `year` = ? AND `month` = ?'
		s.bind_params(y, m)
	end
	r = s.execute
	r.each do |row|
		pageviews = row[0]
	end

	# Get unique visitors for given period.
	visitors = 0
	if (y.nil?)
		s = $db.prepare 'SELECT COUNT(*) FROM `visitors`'
	elsif (m.nil?)
		s = $db.prepare 'SELECT COUNT(*) FROM `visitors` WHERE `year` = ?'
		s.bind_params(y)
	else
		s = $db.prepare 'SELECT COUNT(*) FROM `visitors` WHERE `year` = ? AND `month` = ?'
		s.bind_params(y, m)
	end
	r = s.execute
	r.each do |row|
		visitors = row[0]
	end

	# Generate HTML page.
	File.open(WEBPATH + '/' + id + '.html', 'w') do |f|

		f.write('<!DOCTYPE HTML>' + "\n")
		f.write('<html>' + "\n")
		f.write('<head>' + "\n")
		f.write('<title>' + WEBSITENAME + ' - ' + name + '</title>' + "\n")
		f.write('<link rel="stylesheet" type="text/css" href="main.css" />' + "\n")
		f.write('<script type="text/javascript" src="main.js"></script>' + "\n")
		f.write('</head>' + "\n")
		f.write('<body>' + "\n\n")

		f.write('<h1>' + WEBSITENAME + ' - ' + name + '</h1>' + "\n")
		f.write('<canvas id="pagegraph" class="pagegraph" width="700" height="200"></canvas>' + "\n")
		f.write('<div class="pagesummary">' + "\n")
		f.write('<div>' + formatnumber(pageviews) + ' page views</div>' + "\n")
		f.write('<div>' + formatnumber(visitors) + ' unique visitors</div>' + "\n")
		f.write('</div>' + "\n\n")

		# Generate table for pages.
		f.write('<div class="pagestable">' + "\n")
		f.write('<div><div onclick="sortbydata(event)">Page</div><div onclick="sortbyviews(event)">Views</div></div>' + "\n")
		max = 0
		if (y.nil?)
			s = $db.prepare 'SELECT `page`, SUM(`count`) FROM `pages` GROUP BY `page` ORDER BY SUM(`count`) DESC'
		elsif (m.nil?)
			s = $db.prepare 'SELECT `page`, SUM(`count`) FROM `pages` WHERE `year` = ? GROUP BY `page` ORDER BY SUM(`count`) DESC'
			s.bind_params(y)
		else
			s = $db.prepare 'SELECT `page`, SUM(`count`) FROM `pages` WHERE `year` = ? AND `month` = ? GROUP BY `page` ORDER BY SUM(`count`) DESC'
			s.bind_params(y, m)
		end
		r = s.execute
		r.each do |row|
			max = row[1].to_f / pageviews
			break
		end
		r.reset()
		r.each do |row|
			f.write('<div><div>' + row[0] + '</div><div><span style="width:' + (row[1].to_f / pageviews / max * 100).round.to_s + '%;"></span></div><div>' + formatnumber(row[1]) + '</div></div>' + "\n")
		end
		f.write('</div>' + "\n")
		f.write('<div class="pagemore" id="pagemore" onclick="showmore(event);"><a>More...</a></div>' + "\n\n")

		# Generate table for countries.
		f.write('<div class="pagestable">' + "\n")
		f.write('<div><div onclick="sortbydata(event)">Country</div><div onclick="sortbyviews(event)">Views</div></div>' + "\n")
		max = 0
		if (y.nil?)
			s = $db.prepare 'SELECT `country`, SUM(`count`) FROM `countries` GROUP BY `country` ORDER BY SUM(`count`) DESC'
		elsif (m.nil?)
			s = $db.prepare 'SELECT `country`, SUM(`count`) FROM `countries` WHERE `year` = ? GROUP BY `country` ORDER BY SUM(`count`) DESC'
			s.bind_params(y)
		else
			s = $db.prepare 'SELECT `country`, SUM(`count`) FROM `countries` WHERE `year` = ? AND `month` = ? GROUP BY `country` ORDER BY SUM(`count`) DESC'
			s.bind_params(y, m)
		end
		r = s.execute
		r.each do |row|
			max = row[1].to_f / pageviews
			break
		end
		r.reset()
		r.each do |row|
			country = $countryname.has_key?(row[0]) ? $countryname[row[0]] : row[0]
			f.write('<div><div>' + country + '</div><div><span style="width:' + (row[1].to_f / pageviews / max * 100).round.to_s + '%;"></span></div><div>' + formatnumber(row[1]) + '</div></div>' + "\n")
		end
		f.write('</div>' + "\n")
		f.write('<div class="pagemore" id="pagemore" onclick="showmore(event);"><a>More...</a></div>' + "\n\n")

		# Display menu for available dates.
		($aye..$ays).each do |yi|
			f.write('<div class="pagedates" id="pagedates">' + "\n")
			f.write('<div>' + "\n")
			a = (yi == y and m.nil? ) ? ' class="active"' : ''
			f.write('<a' + a + ' href="' + sprintf('%04d', yi) + '.html">' + sprintf('%04d', yi) + '</a>' + "\n")
			f.write('</div><div>' + "\n")
			msi = $ays == yi ? $ams : 1
			mei = $aye == yi ? $ame : 12
			(msi..mei).each do |mi|
				a = (yi == y and mi == m) ? ' class="active"' : ''
				f.write('<a' + a + ' href="' + sprintf('%04d', yi) + '-' + sprintf('%02d', mi) + '.html">' + sprintf('%04d', yi) + '-' + sprintf('%02d', mi) + '</a>' + "\n")
			end
			f.write('</div>' + "\n")
			f.write('</div>' + "\n\n")
		end

		# Generate page views data for the graph.
		f.write('<script>' + "\n")
		f.write('graphdata={' + "\n")
		ar = {}
		if (y.nil?)
			# Only show data from full months.
			ys = $ays
			ms = $ams
			ds = $ads
			ye = $aye
			me = $ame
			de = $ade
			if ds != 1 and (ys < ye or ms < me)
				ms += 1
				ds = 1
			end
			if de != calendardays(ye, me) and (ys < ye or ms < me)
				me -= 1
				de = calendardays(ye, me)
			end
			# Provide no data unless there's 2 full months of data or more.
			if ys != ye or ms != me
				(ys..ye).each do |yi|
					msi = ys == yi ? ms : 1
					mei = ye == yi ? me : 12
					(msi..mei).each do |mi|
						ar[sprintf('%04d', yi) + '-' + sprintf('%02d', mi)] = '0'
					end
				end
				intms = (sprintf('%04d', ys) + sprintf('%02d', ms) + '00').to_i
				intme = (sprintf('%04d', ye) + sprintf('%02d', me) + '00').to_i
				s = $db.prepare 'SELECT `year`, `month`, SUM(`count`) FROM `pageviews` WHERE `year` * 10000 + `month` * 100 BETWEEN ? AND ? GROUP BY `year`, `month`'
				s.bind_params(intms, intme)
				r = s.execute
				r.each do |row|
					ar[sprintf('%04d', row[0]) + '-' + sprintf('%02d', row[1])] = row[2].to_s
				end
				s.close
			end
		elsif (m.nil?)
			ms = 1
			me = 12
			(ms..me).each do |mi|
				ar[sprintf('%04d', y) + '-' + sprintf('%02d', mi)] = '0'
			end
			s = $db.prepare 'SELECT `month`, SUM(`count`) FROM `pageviews` WHERE `year` = ? GROUP BY `month`'
			s.bind_params(y)
			r = s.execute
			r.each do |row|
				ar[sprintf('%04d', y) + '-' + sprintf('%02d', row[0])] = row[1].to_s
			end
			s.close
		else
			ds = 1
			de = calendardays(y, m)
			(ds..de).each do |di|
				ar[sprintf('%04d', y) + '-' + sprintf('%02d', m) + '-' + sprintf('%02d', di)] = '0'
			end
			s = $db.prepare 'SELECT `day`, SUM(`count`) FROM `pageviews` WHERE `year` = ? AND `month` = ? GROUP BY `day`'
			s.bind_params(y, m)
			r = s.execute
			r.each do |row|
				ar[sprintf('%04d', y) + '-' + sprintf('%02d', m) + '-' + sprintf('%02d', row[0])] = row[1].to_s
			end
			s.close
		end
		ar.each do |k, v|
			f.write('\'' + k + '\':' + v + ',' + "\n")
		end
		f.write('}' + "\n")
		f.write('drawgraph();' + "\n")
		f.write('</script>' + "\n\n")

		f.write('</body>' + "\n")
		f.write('</html>')

	end

end

checkEnvironment()

checkStartPoint()

loadStats()

importData()

saveStats()

filterBots()

cleanEnvironment()

generatePages()
