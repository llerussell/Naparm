function PV = mw2pv(mW)

yaml = ReadYaml('settings.yml');
load(yaml.LaserPowerFile);

PV = polyval(power_file.p, mW);
