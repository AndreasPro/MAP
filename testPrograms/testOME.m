function testOME(paramsName, paramChanges)

savePath=path;
addpath (['..' filesep 'utilities'],['..' filesep 'MAP'])

if nargin<2
    paramChanges=[];
end

sampleRate=50000;

dt=1/sampleRate;
leveldBSPL=80; 		% dB SPL as used by Huber (may trigger AR)
amp=10^(leveldBSPL/20)*28e-6;
duration=.05;
time=dt: dt: duration;

%% Comparison data (human)
% These data are taken directly from Huber 2001 (Fig. 4)
HuberFrequencies=[600	  800	 1000	 2000	 3000	4000 6000 8000];
HuberDisplacementAt80dBSPL=[1.5E-9	1.5E-09	1.5E-09	1.0E-09	7.0E-10	...
    3.0E-10	2.0E-10	1.0E-10]; % m;
% HuberVelocityAt80dBSPL= 2*pi*HuberFrequencies.*HuberDisplacementAt80dBSPL;

figure(2), clf, subplot(2,1,1)
set(2,'position',[5   349   268   327])
semilogx(HuberFrequencies, 20*log10(HuberDisplacementAt80dBSPL/1e-10),...
    'ko', 'MarkerFaceColor','k', 'Marker','o', 'markerSize',6)
hold on

%% Generate test stimulus .................................................................

% independent test using discrete frequencies
peakResponses=[];
peakTMpressure=[];
frequencies=[200 400 HuberFrequencies 10000];
for toneFrequency=frequencies
    inputSignal=amp*sin(2*pi*toneFrequency*time);

    showPlotsAndDetails=0;
    AN_spikesOrProbability='probability';
    % switch off AR & MOC (Huber's patients were deaf)
    paramChanges{1}='OMEParams.rateToAttenuationFactorProb=0;';
    paramChanges{2}='DRNLParams.rateToAttenuationFactorProb = 0;';

    global OMEoutput  OMEextEarPressure TMoutput ARattenuation
    % BF is irrelevant
    MAP1_14(inputSignal, sampleRate, -1, ...
        paramsName, AN_spikesOrProbability, paramChanges);

    peakDisplacement=max(OMEoutput(floor(end/2):end));
    peakResponses=[peakResponses peakDisplacement];

    peakTMpressure=[peakTMpressure max(OMEextEarPressure)];
    disp([' AR attenuation (dB):   ' num2str(20*log10(min(ARattenuation)))])
end

%% Report
disp('frequency displacement(m)')
% disp(num2str([frequencies' peakResponses']))
fprintf('%6.0f \t%10.3e\n',[frequencies' peakResponses']')

% stapes peak displacement
figure(2), subplot(2,1,1), hold on
semilogx(frequencies, 20*log10(peakResponses/1e-10), 'r', 'linewidth',4)
set(gca,'xScale','log')
% ylim([1e-11 1e-8])
xlim([100 10000]), ylim([0 30])
grid on
title(['stapes at ' num2str(leveldBSPL) ' (NB deaf)'])
ylabel('disp: dB re 1e-10m')
xlabel('stimulus frequency (Hz)')
legend({'Huber et al','model'},'location','southWest')
set(gcf,'name','OME')

% external ear resonance
figure(2), subplot(2,1,2),hold off
semilogx(frequencies, 20*log10(peakTMpressure/28e-6)-leveldBSPL,...
    'k', 'linewidth',2)
xlim([100 10000]) %, ylim([-10 30])
grid on
title(['External ear resonances' ])
ylabel('dB')
xlabel('frequency')
set(gcf,'name','OME: external resonances')
% ---------------------------------------------------------- display parameters
disp(['parameter file was: ' paramsName])
fprintf('\n')

path(savePath);
