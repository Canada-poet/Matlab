% Data size: 8735*23499, no header
% Data IO
clear,clc
cd /home/akb/Code/Matlab
temp = '/media/akb/2026EF9426EF696C/raw_data/PiSAR2_07507_13170_009_131109_L090_CX_01_grd/';
if(0)
	fprintf('Parsing input file...')
	fid = fopen([temp 'PiSAR2_07507_13170_009_131109_L090HHHH_CX_01.grd'],'r','ieee-le'); 
	%hh_hh = single(rot90(fread(fid,[23499,8735],'real*4')));
	hh_hh = sparse(rot90(fread(fid,[23499,8735],'real*4')));
	fid = fopen([temp 'PiSAR2_07507_13170_009_131109_L090HVHV_CX_01.grd'],'r','ieee-le'); 
	%hv_hv = single(rot90(fread(fid,[23499,8735],'real*4')));
	hv_hv = sparse(rot90(fread(fid,[23499,8735],'real*4')));
	fid = fopen([temp 'PiSAR2_07507_13170_009_131109_L090VVVV_CX_01.grd'],'r','ieee-le'); 
	%vv_vv = single(rot90(fread(fid,[23499,8735],'real*4')));
	vv_vv = sparse(rot90(fread(fid,[23499,8735],'real*4')));

	fid = fopen([temp 'PiSAR2_07507_13170_009_131109_L090HVVV_CX_01.grd'],'r','ieee-le'); 
	hv_vv = fread(fid,[23499*2,8735],'real*4');
	%hv_vv = single(rot90(hv_vv(1:2:end, :) + 1j*hv_vv(2:2:end, :)));
	hv_vv = sparse((rot90(hv_vv(1:2:end, :) + 1j*hv_vv(2:2:end, :))));
	fid = fopen([temp 'PiSAR2_07507_13170_009_131109_L090HHVV_CX_01.grd'],'r','ieee-le'); 
	hh_vv = fread(fid,[23499*2,8735],'real*4');
	%hh_vv = single(rot90(hh_vv(1:2:end, :) + 1j*hh_vv(2:2:end, :)));
	hh_vv = sparse(rot90(hh_vv(1:2:end, :) + 1j*hh_vv(2:2:end, :)));
	fid = fopen([temp 'PiSAR2_07507_13170_009_131109_L090HHHV_CX_01.grd'],'r','ieee-le'); 
	hh_hv = fread(fid,[23499*2,8735],'real*4');
	%hh_hv = single(rot90(hh_hv(1:2:end, :) + 1j*hh_hv(2:2:end, :)));
	hh_hv = sparse(rot90(hh_hv(1:2:end, :) + 1j*hh_hv(2:2:end, :)));
	fclose(fid) ;
	clear fid
	save([temp 'Covariance_ds.mat'],'-v7.3', 'hh_hh', 'hv_hv', 'vv_vv', 'hh_hv', 'hh_vv', 'hv_vv');
else
	fprintf('Loading...')
	load([temp 'Covariance.mat']);
	%load([temp 'Covariance_d.mat']);
	%load([temp 'Covariance_ds.mat']);
end	
fprintf('\n')
if(0)
	figure(1)
		imagesc(10*log10(hh_hh))
		set(gca,'Ydir','normal')
		title('$10 log |S_{hh}|^2$', 'Interpreter', 'latex'), colorbar, colormap gray;
		caxis([-30 20])
	figure(2)
		imagesc(10*log10(hv_hv))
		set(gca,'Ydir','normal')
		title('$10 \log |S_{hv}|^2$', 'Interpreter', 'latex'), colorbar, colormap gray;
		caxis([-30 20])
	figure(3)
		imagesc(10*log10(vv_vv))
		set(gca,'Ydir','normal')
		title('$10 \log |S_{vv}|^2$', 'Interpreter', 'latex'), colorbar, colormap gray;
		caxis([-30 20])
	figure(4)
		imagesc(10*log10(vv_vv./hh_hh))
		set(gca,'Ydir','normal')
		title('$10 \log \frac{|S_{vv}|^2}{|S_{hh}|^2}$', 'Interpreter', 'latex'), colorbar, colormap jet;
		caxis([-8 4])
		plot_para('Filename','criteria','Maximize',true)
	Pauli_g = 10*log10(hh_hh+2*hv_hv+vv_vv);
	figure(5)
		imagesc(Pauli_g)
		xlabel('azimuth')
		set(gca,'Ydir','normal'), colorbar, colormap gray;
		caxis([-30 20])
		plot_para('Filename','My_pauli_g','Maximize',true)
	clear Pauli_g;
end

%% Pauli decomposition
[row, col] = size(hh_hh);
non_z_ind = (hh_hh ~= 0);
are_z = ~non_z_ind;

if(0)	% Plot the Pauli-decomposition.
	up_ = 10; low_ = -20;
	Pauli = ones(row, col, 3);	
	t_p = 10*log10(sqrt(hh_hh + vv_vv - hh_vv - conj(hh_vv)));	% |S_vv - S_hh|^2 -> double bounce scattering 
	t_p(t_p < low_) = low_;
	t_p(t_p > up_ ) = up_;
	Pauli(:,:,1) = (t_p-low_)/(up_-low_);	
	t_p= 10*log10(4*sqrt(hv_hv));									% |S_hv|^2 -> volume scattering
	t_p(t_p < low_) = low_;
	t_p(t_p > up_ ) = up_;
	Pauli(:,:,2) = (t_p-low_)/(up_-low_);
	t_p = 10*log10(sqrt(hh_hh + vv_vv + hh_vv + conj(hh_vv)));	% |S_vv + S_hh|^2 -> single scattering
	t_p(t_p < low_) = low_;
	t_p(t_p > up_ ) = up_;
	Pauli(:,:,3) = (t_p-low_)/(up_-low_);
	figure(6)
		image(Pauli)
		set(gca,'Ydir','normal')
		%xlim([7500 8200])
		%ylim([2000 2600])
		xlabel('azimuth')
		plot_para('Filename','My_pauli_c','Maximize',true)
	clear Pauli t_p
	%{
	figure(7)
		image(imread([temp 'PiSAR2_07507_13170_009_131109_L090_CX_01_pauli.tif']))
		plot_para('Maximize',true)
	%}
end
																																																													
%% Four-component decomposition (option: compensate the orientation)
fprintf('Compensate the oriented angle or not? CAUTION! THIS WILL CHANGE hh_hh, vv_vv, etc PERMANENTLY. \n')
P_t = hh_hh + vv_vv + 2*hv_hv;
if(0)
	fprintf('Yes.  \n')
	filename = 'Four_compoR';
	%R = [1, 0, 0; 0, cos(2*x), sin(2*x); 0, -sin(2*x), cos(2*x)];
	%R = 0.5*[1+cos(2*x), sqrt(2)*sin(2*x), 1-cos(2*x); -sqrt(2)*sin(2*x), 2*cos(2*x), sqrt(2)*sin(2*x); 1-cos(2*x), -sqrt(2)*sin(2*x), 1+cos(2*x)];
	x = -0.5*atan((2*sqrt(2)*real(hv_vv-hh_hv))./(are_z+hh_hh+vv_vv-2*real(hh_vv)-2*hv_hv)).*non_z_ind;
	x(x>pi/2) = x(x>pi/2)-pi;
	x(x<-pi/2) = x(x<-pi/2)+pi;
	%temp = R*[hh_hh, hh_hv, hh_vv; conj(hh_vv), hv_hv, hv_vv; conj(hh_vv), conj(hv_vv), vv_vv]*R.';
	C = cell(3); R = cell(3); C_n = cell(3);
	C{1,1} = hh_hh; C{1,2} = hh_hv; C{1,3} = hh_vv;
	C{2,2} = hv_hv; C{2,3} = hv_vv; C{3,3} = vv_vv;
	clear hh_hh hh_hv hh_vv hv_hv hv_vv vv_vv 
	R{1,1} = 0.5*(1+cos(2*x)); R{1,2} = -0.5*sqrt(2)*sin(2*x); R{1,3} = 0.5*(1-cos(2*x));
	R{2,2} = cos(2*x); R{2,3} = -0.5*sqrt(2)*sin(2*x); R{3,3} = 0.5*(1+cos(2*x));
	clear x
	for n = 1 : 3
		for m = n : 3
			C_n{n,m} = single(zeros(row,col));
		end
	end
	
	for n = 1 : 3
		for m = n : 3
			for q = 1 : 3
				if n>q && q>m
					C_n{n,m} = C_n{n,m} + conj(C{q,n})*(1-mod(m+q,2)).*R{m,q};
				elseif n>q
					C_n{n,m} = C_n{n,m} + conj(C{q,n}).*R{q,m};
				elseif q>m
					C_n{n,m} = C_n{n,m} + C{n,q}*(1-mod(m+q,2)).*R{m,q};
				else
					C_n{n,m} = C_n{n,m} + C{n,q}.*R{q,m};
				end
			end
		end
	end
	for n = 1 : 3
		for m = n : 3
			C{n,m} = single(zeros(row,col));
		end
	end
	
	R{1,2} = -R{1,2}; R{2,3} = -R{2,3};
	for n = 1 : 3
		for m = n : 3
			for q = 1 : 3
				if n>q && q>m
					C{n,m} = C{n,m} + (1-2*mod((q+n),2))*R{q,n}.*conj(C_n{m,q});
				elseif q>m
					C{n,m} = C{n,m} + R{n,q}.*conj(C_n{m,q});
				elseif n>q
					C{n,m} = C{n,m} + (1-2*mod((q+n),2))*R{q,n}.*C_n{q,m};
				else
					C{n,m} = C{n,m} + R{n,q}.*C_n{q,m};
				end
			end
		end
	end
	hh_hh = real(C{1,1}); hh_hv = C{1,2}; hh_vv = C{1,3};
	hv_hv = real(C{2,2}); hv_vv = C{2,3}; vv_vv = real(C{3,3});
	clear C C_n R x
else
	filename = 'Four_compo';
	fprintf('No. \n')
end
%%
% f_ is the scattering matrix coefficient. The subscript
% f_s: surface, f_d: double-bounce, f_v: volume, f_c: helix 
f_c = 2 *abs(imag(hh_hv + hv_vv));

% Decide which volume scattering model is used.
% With three interval (-infty,-2dB) [-2dB, 2dB) [2dB, infty)

crit_fv = 10*log10(vv_vv./(hh_hh + are_z*0.001)); 
temp_domain = (crit_fv >= -2) .*(crit_fv <= 2);
f_v = (8*hv_hv - 2*f_c) .*temp_domain;
temp = f_v<0;
f_v(temp) = f_v(temp) + 2*f_c(temp);
f_temp = 15/2*(hv_hv - f_c/4).*(f_v == 0);
temp = f_temp < 0;
f_temp(temp) = f_temp(temp) + 15/8*f_c(temp);
f_v = f_temp + f_v;
clear f_temp temp

% Decide double scattering or single scattering domainate 
S = hh_hh + vv_vv + hh_vv + conj(hh_vv) - 0.5*f_v;
D = (hh_hh + vv_vv - hh_vv - conj(hh_vv)) - 2*hv_hv.*temp_domain ......
	-(7/30*f_v+0.5*f_c).*(~temp_domain); 
C = vv_vv - hh_hh + hh_vv - conj(hh_vv) - 1/6*f_v.*(crit_fv<-2) + 1/6*f_v.*(crit_fv>2);
clear temp_domain crit_fv

% surface dominates alpha = -1
temp_dom = 4*real(hh_vv) - 2* hv_hv - f_c > 0;
P_s = (S + abs(C).^2./S).*temp_dom;
P_d = (D - abs(C).^2./S).*temp_dom;
% Double-dominates beta = 1
temp_dom = 4*real(hh_vv) - 2* hv_hv - f_c < 0;
P_s = P_s + (D+abs(C).^2./D).*temp_dom;
P_d = P_d + (S-abs(C).^2./D).*temp_dom;
clear S D C
% The contribution from each scattering mechanism

% The power contribution should be positive. Let the negative power be zero.
%P_t = hh_hh + vv_vv + 2*hv_hv
temp_dom = P_s < 0;
P_s(temp_dom) = 0; 
P_d(temp_dom) = P_t(temp_dom) - f_c(temp_dom) - f_v(temp_dom);
temp_dom = P_d < 0;
P_d(temp_dom) = 0;
P_s(temp_dom) = P_t(temp_dom) - f_c(temp_dom) - f_v(temp_dom);

temp_dom = f_c+f_v > P_t;
P_s(temp_dom) = 0; P_d(temp_dom) = 0;
f_v(temp_dom) = P_t(temp_dom) - f_c(temp_dom);
f_v(f_v<0) = 0;
clear temp_dom

if(0)
	figure(8)
		imagesc(10*log10(P_t))
		xlabel('azimuth')
		set(gca,'Ydir','normal'), colorbar, colormap gray;
		caxis([-30 20])
		plot_para('Maximize',true)
	figure(9)
		imagesc(10*log10(f_c))
		xlabel('azimuth')
		set(gca,'Ydir','normal'), colorbar, colormap gray;
		caxis([-30 20])
		plot_para('Maximize',true)
end

if(1)	% Plot the 4-component decomposition.
	FourCompo = single(zeros(row, col, 3));
	up_ = 20; low_ = -30;
	FourCompo(:,:,1) = 10*log10(P_d);
	FourCompo(:,:,2) = 10*log10(f_v);
	FourCompo(:,:,3) = 10*log10(P_s);
	clear P_d  f_v P_s f_c f_d f_s 
	FourCompo(FourCompo < low_) = low_;
	FourCompo(FourCompo > up_) = up_;
	FourCompo = (FourCompo-low_)/(up_-low_);
	figure(10)
		image(FourCompo)
		set(gca,'Ydir','normal')
		xlabel('azimuth')
		%xlim([8100 8900])
		%ylim([2800 3100])
		plot_para('Filename',filename,'Maximize',true)
		%plot_para('Maximize',true)
	clear FourCompo filename
end

%% eigenvalue model-based 4-component decomposition
% Build table
if(0) 
	fprintf('Building table...')
	f_s = 0:0.1:1; f_d = 0:0.1:1; theta = 0:pi/12:pi/4;
	beta = 0.2:0.2:1; 
	chi = [];
	for n = -1 : 0.2: -0.2
		for m = 0.8: -0.2: 0
			if abs(n + 1j*m)<=1 
				chi = [chi, n + 1j*m];
			end
		end
	end

	C_v(:,:,1) = 1/8*[3, 0, 1; 0, 2, 0; 1, 0, 3];
	C_v(:,:,2) = 1/15*[8, 0, 2; 0, 4, 0; 2, 0, 3];
	C_v(:,:,3) = 1/8*[3, 0, 2; 0, 4, 0; 2, 0, 8];
	table = [];
	for k = 1 : numel(theta)
		for n = 1 : numel(f_s)
			for m = 1 : numel(f_d)
				if f_s(n) + f_d(m) > 1
					continue
				else
					f_v = 1 - f_s(n) - f_s(m);
				end
				R = 0.5*[1+cos(2*theta(k)), sqrt(2)*sin(2*theta(k)), 1-cos(2*theta(k)); -sqrt(2)*sin(2*theta(k)), 2*cos(2*theta(k)), sqrt(2)*sin(2*theta(k));......
					1-cos(2*theta(k)), -sqrt(2)*sin(2*theta(k)), 1+cos(2*theta(k))];
				for beta_it = 1: numel(beta)
					for chi_it = 1: numel(chi)
						for cv_it = 1 : 3
							% template = [x^2, 0, x; 0,0,0; x^*,0,1];
							C_s = 1/(abs(chi(chi_it))^2 + 1)*[abs(chi(chi_it))^2, 0, chi(chi_it); 0,0,0; conj(chi(chi_it)),0,1];
							C_d = 1/(abs(beta(beta_it)^2) + 1)*[beta(beta_it)^2, 0, beta(beta_it); 0,0,0; conj(beta(beta_it)),0,1];
							C = f_s(n)*C_s + f_d(m)*R*C_d*R.' + f_v*C_v(:,:,cv_it);
							[V, p] = eig(C);
							alpha = acos(sqrt(abs(V(:,1) + V(:,3)).^2/2));
							p = p/sum(p);
							table = [table; f_s(n), f_d(m), f_v, p(3:-1:2).', alpha.'];
							%table(cv_it,:) = [f_s(n), f_d(m), f_v, p(3:2).', alpha.'];
						end
					end
				end
			end
		end
		fprintf('.')
	end
	save('4comp_table.mat', 'table')
	clear chi_it beta_it cv_it k n m 
else
	fprintf('Loading table...')
	load('4comp_table.mat')
end
fprintf('\n')
%% Query	 
P_h = single(zeros(row, col));
P_s = P_h; P_d = P_h; P_v = P_h;

[r_n, c_n] = find(non_z_ind);
temp = size(r_n);
% 2780 : 2880
% 8300 : 8500		%xlim([8100 8900])
		%ylim([2800 3100])
parfor m = 2800 : 3100
	for n = 8100 : 8900
	C = [hh_hh(m,n), sqrt(2)*hh_hv(m,n), hh_vv(m,n); sqrt(2)*conj(hh_hv(m,n)), 2*hv_hv(m,n), sqrt(2)*hv_vv(m,n);......
		conj(hh_vv(m,n)), sqrt(2)*conj(hv_vv(m,n)), vv_vv(m,n)];
	[V, p] = eig(C);
	alpha = acos(sqrt(abs(V(:,1) + V(:,3)).^2/2));
	delta = acos(abs((V(:,3)-V(:,1)+1j*sqrt(2)*V(:,2))/2)./sin(alpha));
	hel = sin(alpha.^2).*(cos(delta.^2)- sin(delta.^2));
	% f_s(n), f_d(m), f_v, p(3:-1:2).', alpha.'
	P_h(m,n) = abs(sum(p*hel));
	p = real(p/sum(p));
	P_r = P_t(m,n) - P_h(m,n);

	eta = 0.25*atan((-2*sqrt(2)*real(V(:,3)-V(:,1).*conj(V(:,2))))/abs(V(:,3)-V(:,1)).^2 - abs(V(:,2)).^2);
	eta(eta>pi/4) = eta(eta>pi/4) - pi/2;
	d_theta = abs(eta(3)-eta(2));

	if d_theta > pi/4
		d_theta = -d_theta + pi/2;
	end
	if d_theta <= pi/24
		u = [1,19800];
	elseif pi/24 < d_theta <= pi/8
		u = [19801,39600];
	elseif pi/8 < d_theta <= 5*pi/24
		u = [39601,59400];
	elseif 5*pi/24 < d_theta <= pi/4
		u = [59401,79200];
	end

	diff = realmax('single');
	diff_t = 0;
	for t = u(1) : u(2)
		temp = 0.5*(p(3)-table(t,4))^2 + 0.5*(p(2)-table(t, 5))^2 + sum([table(t,4:5), 1-sum(table(t,4:5))].*((table(t,6:8)-alpha.')*2/pi).^2);
		if(diff>temp)
			diff = temp;
			diff_t = t
		end
	end
	P_d(m,n) = P_r*table(diff_t,2); 
	P_s(m,n) = P_r*table(diff_t,1); 
	P_v(m,n) = P_r*table(diff_t,3);
	end
	if ~mod(m,20)
		fprintf('.') 
	end
end

clear a b 

if(1)	% Plot the 4-component + eigenvalue decomposition.
	FourCompo = single(zeros(row, col, 3));
	up_ = 20; low_ = -30;
	FourCompo(:,:,1) = 10*log10(P_d);
	FourCompo(:,:,2) = 10*log10(P_v);
	FourCompo(:,:,3) = 10*log10(P_s);
	%clear P_d  P_v P_s 
	FourCompo(FourCompo < low_) = low_;
	FourCompo(FourCompo > up_) = up_;
	FourCompo = (FourCompo-low_)/(up_-low_);
	figure(12)
		image(FourCompo)
		set(gca,'Ydir','normal')
		xlabel('azimuth')
		xlim([8300 8500])
		ylim([2780 2880])
		plot_para('Filename','4com_eigen','Maximize',true,'Ratio', [7 5 1])
		%plot_para('Maximize',true)
	clear FourCompo
end
%%
%{
m = 2900; n = 8500;
C = [hh_hh(m,n),hh_hv(m,n),hh_vv(m,n); conj(hh_hv(m,n)), hv_hv(m,n),hv_vv(m,n);......
		conj(hh_vv(m,n)), conj(hv_vv(m,n)), vv_vv(m,n)];
m = 2901; n = 8501;
D = [hh_hh(m,n),hh_hv(m,n),hh_vv(m,n); conj(hh_hv(m,n)), hv_hv(m,n),hv_vv(m,n);......
		conj(hh_vv(m,n)), conj(hv_vv(m,n)), vv_vv(m,n)];
[V, p] = eig(C)
[V, p] = eig(D)
C = [C zeros(3,3); zeros(3,3) D];
[V, p] = eig(C)
eigs(sparse(double(C)))
%}