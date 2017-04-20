function [v_yt] = DualRx(vx,vy,ax,ay)
% This function generate the SAR signal regarding to the input parameter.
% Usage: Gen_signal(vx, vy, ax, ay), 'vx' is range velocity, 'vy' is azimuth
% velocity, 'ax' is range accelaration and 'ay' is azimuth accelration. If no input parameters, the velocity in both direction are set
% to zero
% Noth that the parameters of SAR need to be modified in the function.
%{
    delete parameter.mat
    if nargin == 0
        vx = 0; vy = 0; 
        ax = 0; ay = 0;
    end
%}

    %% Parameters - C Band airborne SAR parameters
    % Target
    x_0 = 2160;
    y_0 = 400;
	
    d = 100; % Length of the target area 
    v_x = vx; a_x = ax; % rangecl -16
    v_y = vy; 
	a_y = ay; % azimuth 
    % Platform
    h = 2200;
	R_0 = sqrt(x_0^2 + y_0^2 + h^2);
	l_0 = sqrt( y_0^2 + h^2);
    d_a = 0.2;     
    v_p = 90; 
    f_0 = 9.6e9; c = 3e8 ; lambda = c/f_0 ;
    dur = 2 ; %
    PRF = 1000; %%2.35e3
    K_r = 5e14 ;
    T_p = 0.1e-6; % Pulse width
    B =  K_r*T_p;
    %% Signal 
    aa = 0;
    eta = linspace( aa - dur/2, aa + dur/2,PRF*dur) ;  % Slow time -6

    upran = sqrt( (x_0 + d)^2 + h^2) ; downran =  sqrt( (x_0 - d)^2 + h^2); %Set upper limit and down limit 
    tau =  2*(downran)/c: 1/4/B : 2*(upran)/c + T_p  ;  % fast time space

    R1 = sqrt(h^2 + (x_0 + v_x* eta + 0.5* a_x* eta.^2).^2 + (y_0 + v_y* eta + 0.5* a_y * eta.^2 - v_p* eta).^2 ) ; % range equation
    R2 = sqrt(h^2 + (x_0 + v_x* eta + 0.5* a_x* eta.^2).^2 + (d_a + y_0 + v_y* eta + 0.5* a_y * eta.^2 - v_p* eta).^2 ) ; % range equation
   
    s1 = zeros(length(eta), length(tau));
	s2 = zeros(length(eta), length(tau));
    for k = 1 : length(eta)
        td1 = 2* R1(k)/ c ;
		td2 = (R1(k) + R2(k)) /c ;
        s1(k,:) = exp(-i* 4* pi*R1(k)/ lambda + i* pi* K_r* (tau - 2* R1(k)/ c).^2) .*(tau>=td1 & tau-td1<=T_p)  ;
		s2(k,:) = exp(-i* 2* pi*(R1(k) + R2(k))/ lambda + i* pi* K_r* (tau - (R1(k) + R2(k) )/ c).^2) .*(tau>=td2 & tau-td2<=T_p)  ;
	end
	%purinto(s1)
	%purinto(s2)
	clear R1 R2
	%% range compression 
	ref_time = -T_p : 1/4/B : 0 ;
	h_m = repmat(exp(j * 4 * pi * f_0 * R_0 / c) *  exp(- j * pi * K_r * ref_time.^2),length(eta),1 ) ; 

	tau_nt2 = nextpow2(length(tau)) ;  % Make total number to power of 2
    Fh_m = fft( h_m.', 2^tau_nt2 ).'; 
    Fs1_rc = fft(s1.', 2^tau_nt2).' .* Fh_m; % Range compression
    s1_rc = ifft( Fs1_rc.' ).';
    Fs2_rc = fft(s2.', 2^tau_nt2).' .* Fh_m; % Range compression
	s2_rc = ifft( Fs2_rc.' ).';
	clear Fh_m s1 s2
	%purinto(s1_rc)
	%% Key Stone transform - RCMC for range curveture 
	% Interpolation 
    f_tau = linspace(0, 4*B -1, 2^tau_nt2 ); 
    shift = 0; % FFTshift false
    if shift == 1
    	f_tau = linspace(-2*B, 2*B -1, 2^tau_nt2 ); 
    	Fs_rc = fftshift(Fs_rc, 2);
	end
	
	t = eta.' * sqrt((f_0 + f_tau)/f_0);
	Fs1_1 = zeros(floor(t(end,end)*PRF*dur),2^tau_nt2);
	Fs2_1 = Fs1_1;
	for m = 1 : 2^tau_nt2
		temp_cou = floor(PRF*t(end,m)) - 1000;
		Fs1_1(:, m) = [zeros(10-temp_cou,1); ...
			interp1(eta, abs(Fs1_rc(:,m)).', linspace(-1,1, 2000 + 2*temp_cou), 'spline', 0).'; zeros(10-temp_cou,1)];
		Fs1_1(:, m) = Fs1_1(:, m) .* exp(j * [zeros(10-temp_cou,1); ...
			interp1(eta, unwrap(angle(Fs1_rc(:,m))).', linspace(-1,1, 2000 + 2*temp_cou), 'spline', 0).'; zeros(10-temp_cou,1)]);
		%Fs1_1(:, m) = [zeros(10-temp_cou,1); ...
		%	interp1(eta, Fs1_rc(:,m).', linspace(-1,1, 2000 + 2*temp_cou), 'spline', 0).'; zeros(10-temp_cou,1)];
		
		Fs2_1(:, m) = [zeros(10-temp_cou,1); ...
			interp1(eta, abs(Fs2_rc(:,m)).', linspace(-1,1, 2000 + 2*temp_cou), 'spline', 0).'; zeros(10-temp_cou,1)];
		Fs2_1(:, m) = Fs2_1(:,m) .* exp(j * [zeros(10-temp_cou,1); ...
			interp1(eta, unwrap(angle(Fs2_rc(:,m))).', linspace(-1,1, 2000 + 2*temp_cou), 'spline', 0).'; zeros(10-temp_cou,1)]);
	end
	
    if shift == 1
    	s1_1 = ifft(ifftshift(Fs1_1, 2).').'; % If the central of f_tau is 0, then ifftshift is needed. If not so, do not do ifftshift 
		s2_1 = ifft(ifftshift(Fs2_1, 2).').';
    else
    	s1_1 = ifft(Fs1_1.').';
		s2_1 = ifft(Fs2_1.').';
	end
	%{
	purinto(Fs1_rc)
	xlabel('$f_\tau / \Delta f_\tau $', 'Interpreter', 'latex')
	ylabel('$\eta / \Delta \eta$', 'Interpreter', 'latex')
	caxis([0 160])
	%export_fig 1.jpg
	
	purinto(Fs1_1)
	xlabel('$f_\tau / \Delta f_\tau$', 'Interpreter', 'latex')
	ylabel('$t/\Delta t$', 'Interpreter', 'latex')
	caxis([0 160])
	%export_fig 2.jpg
	purinto(Fs2_1)
	xlabel('$f_\tau / \Delta f_\tau$', 'Interpreter', 'latex')
	ylabel('$t/\Delta t$', 'Interpreter', 'latex')
	caxis([0 160])
	
	
	purinto(s1_1)
	xlabel('$\tau /\Delta \tau$', 'Interpreter', 'latex')
	ylabel('$t/\Delta t$', 'Interpreter', 'latex')
	%caxis([0 160])
	%export_fig aa.jpg
	purinto(s2_1)
	xlabel('$\tau /\Delta \tau$', 'Interpreter', 'latex')
	ylabel('$t/\Delta t$', 'Interpreter', 'latex')
	%}

	%% Radon transform to estimate the slop
	% real v_r  and the Doppler frequency
	v_r_real_ = v_x * (h/R_0/sqrt(1-y_0^2/R_0^2) );
	f_dc = 2*v_r_real_ / lambda;
	%fprintf('Doppler frequency %f\n',f_dc)
	
	do_radon = 1;
	if do_radon 
		iptsetpref('ImshowAxesVisible','on')
		theta = [0:0.01:10 165:0.01:180-0.01];
		[R,xp] = radon(abs(s1_1),theta);
		figure
		imagesc(R)
		xlabel('\theta (degrees)')
		ylabel('x''')
		colormap(gca,hot), colorbar
		[~,ind_c] = max(max(R));
		ell = -1/(tand(theta(ind_c)+90)*4*B/PRF);
	else
		[~, down] = max(abs(s1_1(1,:)) );
		[~, up] = max(abs(s1_1(length(s1_1(:,1)),:)));
		x_sl = (up - down) / 4 / B / dur  ;    
		v_rt = c * x_sl ;
	end
    %% RCMC for range walk 
	t = repmat(linspace(-t(end,end),t(end,end),2*floor(PRF*t(end,end))),length(f_tau),1).';
    if do_radon 
		Fh_rw = exp(j * 2 * pi  * ell * t .* repmat(f_tau, length(t(:,1)), 1) );    
	else 
		Fh_rw = exp(j * 4 * pi / c * t / 2 * v_rt .* repmat(f_tau, length(eta), 1) );    
	end
    Fs1_2 = Fs1_1 .* Fh_rw ; 
	Fs2_2 = Fs2_1 .* Fh_rw ; 
	
    if shift == 1
        s1_2 = ifft(ifftshift(Fs1_2, 2).').';
		s2_2 = ifft(ifftshift(Fs2_2, 2).').';
    else
        s1_2 = ifft(Fs1_2.').';
		s2_2 = ifft(Fs2_2.').';
	end
		
	%% Search the parameters by phase 
	
	f = fittype('a*x+b');	
	[fit1,~,~] = fit(t(:,148), unwrap(angle(s1_2(:,148).*conj(s2_2(:,148)))), f,'StartPoint',[1 1]);
	v_yt = v_p + fit1.a * lambda / 2 / pi *R_0 / d_a;
	fprintf('Method 0, Actual: %f, Estimate: %f\n', v_y, v_yt)
	clear f fit1
		
		L =31;
		ind = 148;
		filt_ = [hamming(L).'/sum(hamming(L)); rectwin(L).'/L];
		for gg = 1 : 1
			s_filter = ifft(fft(unwrap(angle(s1_2(:,ind).*conj(s2_2(:,ind))))) .*  fft(filt_(gg,:),length(t(:,1))).'  );
			
			%figure
			%plot(s_filter,'k','Linewidth',2)
			%hold on
			%plot(unwrap(angle(s1_2(:,ind).*conj(s2_2(:,ind)))),'Linewidth',2)
			%xlabel('$\Delta t$', 'Interpreter', 'latex')
			%ylabel('Phase', 'Interpreter', 'latex')
			%plot_para(1,1,int2str(gg))
			
			f = fittype('a*x+b');
			[fit1,~,~] = fit(t(L:end,148),s_filter(L:end) ,'poly1');
			v_yt = v_p + fit1.p1 * lambda / 2 / pi *R_0 / d_a;
			fprintf('Method %d, Actual: %f, Estimate: %f\n', gg, v_y, v_yt)
			
			%figure
			%plot(fit1,t(L:end,148),s_filter(L:end))
			%xlabel('$t$', 'Interpreter', 'latex')
			%ylabel('Phase', 'Interpreter', 'latex')
			%plot_para(1,1,'fit')
			clear f fit1
		end
end
%{	
	%%
	ind = 148;
	plot(ifft(fft(unwrap(angle(s1_2(:,ind).*conj(s2_2(:,ind))))) .*  fft(filt_(gg,:),length(eta)).'  ),'Linewidth',1)
	hold on 
	plot(ifft(fft(unwrap(angle(s1_2(:,ind+1).*conj(s2_2(:,ind+1))))) .*  fft(filt_(gg,:),length(eta)).'  ),'Linewidth',1)
	hold on
	plot(ifft(fft(unwrap(angle(s1_2(:,ind+2).*conj(s2_2(:,ind+2))))) .*  fft(filt_(gg,:),length(eta)).'  ),'Linewidth',1)
	plot_para(1,1,'fit')

%%
close all
rrr= exp(j*2*pi/lambda* (d_a * y_0 / R_0 - d_a*(v_p - v_y)/R_0 * t(:,148)));  
I2 = exp(-j * 4* pi /lambda *(R_0 + d_a * y_0 / 2 / R_0 - d_a*(v_p - v_y)/ 2 / R_0 *t(:,148) ...
        + (v_x * x_0 - y_0 *(v_p - v_y))/ R_0 * t(:,148) + ((v_y - v_p)^2 + a_x * x_0)/2/R_0 * t(:,148).^2 ));
I1 = exp(-j * 4* pi /lambda *(R_0 + ...
        + (v_x * x_0 - y_0 *(v_p - v_y))/ R_0 * t(:,148) + ((v_y - v_p)^2 + a_x * x_0)/2/R_0 * t(:,148).^2 ));

	
figure 
plot(angle(I1))
hold on 
plot(angle(I2))
plot_para(1,1,'1')

figure 
plot(unwrap(angle(I1)))
hold on 
plot(unwrap(angle(I2)))
plot_para(1,1,'2')

figure
yyaxis left
plot(angle(I1) - angle(I2),'Linewidth',2)
yyaxis right
plot(unwrap(angle(I1)) - unwrap(angle(I2)),'Linewidth',2)
plot_para(1,1,'3')


close all
temp = 1 : length(s1_2(:,148));

figure
plot(angle(s1_2(:,148)),'Linewidth',1)
hold on 
plot(angle(s2_2(:,148)),'r','Linewidth',1)
plot_para(1,1,'4')

figure
plot(unwrap(angle(s1_2(:,148))),'Linewidth',1)
hold on 
plot(unwrap(angle(s2_2(:,148))),'r','Linewidth',1)
plot_para(1,1,'5')

figure
yyaxis left
plot(angle(s1_2(:,148)) - angle(s2_2(:,148)),'Linewidth',1)
yyaxis right
plot(unwrap(angle(s1_2(:,148))) - unwrap(angle(s2_2(:,148))),'Linewidth',1)
plot_para(1,1,'6')

figure
plot(angle(s1_2(:,148).*conj(s2_2(:,148))),'Linewidth',1)
hold on 
plot(unwrap(angle(s1_2(:,148))) - unwrap(angle(s2_2(:,148))),'r','Linewidth',1)
plot_para(1,1,'7')

	
figure
plot(t(:,148),angle(s1_2(:,148).*conj(s2_2(:,148))),'k','Linewidth',2)
xlabel('t')
ylabel('Phase')
plot_para(1,1,'7')
%}

%{
	%% Spectrum of the filter
	L = 101;
	lon = 2^10;
	filter = [rectwin(L).'; triang(L).'; hamming(L).'];
	f_spect = linspace(-0.5,0.5,lon);
	figure 
	plot(f_spect,10*log10(fftshift(abs(fft(filter(1,:),lon)  .* conj(fft(filter(1,:),lon))))/max(abs(fft(filter(1,:),lon) .* conj(fft(filter(1,:),lon))))) ,'Linewidth',2)
	hold on 
	plot(f_spect,10*log10(fftshift(abs(fft(filter(2,:),lon)  .* conj(fft(filter(2,:),lon))))/max(abs(fft(filter(2,:),lon) .* conj(fft(filter(2,:),lon))))) ,'Linewidth',2)
	hold on 
	plot(f_spect,10*log10(fftshift(abs(fft(filter(3,:),lon)  .* conj(fft(filter(3,:),lon))))/max(abs(fft(filter(3,:),lon) .* conj(fft(filter(3,:),lon))))) ,'k','Linewidth',2)
	ylim([-50 0])
	xlabel('Normalized frequency','Interpreter', 'latex')
	ylabel('Spectrum (dB)','Interpreter', 'latex')
	plot_para(1,1,'f_respon')
	
	f_spect = linspace(-0.5,0.5,length(eta));
	plot(f_spect,10*log10(fftshift(abs(fft(unwrap(angle(s1_2(:,148).*conj(s2_2(:,148)))))  .* conj(fft(unwrap(angle(s1_2(:,148).*conj(s2_2(:,148))))))))/max(abs(fft(unwrap(angle(s1_2(:,148).*conj(s2_2(:,148))))) .* conj(fft(unwrap(angle(s1_2(:,148).*conj(s2_2(:,148))))))))),'k' ,'Linewidth',2)
	xlabel('Normalized frequency','Interpreter', 'latex')
	ylabel('Spectrum (dB)','Interpreter', 'latex')
	plot_para(1,1,'ATI_Pha_f')
	
%}

