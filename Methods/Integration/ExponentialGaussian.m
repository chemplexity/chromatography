% ------------------------------------------------------------------------
% Method      : ExponentialGaussian
% Description : Curve fitting analysis of chromatographic peaks
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   peaks = ExponentialGaussian(x, y)
%   peaks = ExponentialGaussian( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Required)
% ------------------------------------------------------------------------
%   x -- time values (size = n x 1)
%       array
%
%   y -- intensity values
%       array | matrix (size = n x m)
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'center' -- search window center
%       x at max(y) (default) | number
%
%   'width' -- search window width
%       1 (default) | number
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   peaks = ExponentialGaussian(x, y)
%   peaks = ExponentialGaussian(x, y, 'center', 22.10)
%   peaks = ExponentialGaussian(x, y, 'center', 12.44, 'width', 0.24)
%
% ------------------------------------------------------------------------
% References
% ------------------------------------------------------------------------
%   K. Lan, et. al. Journal of Chromatography A, 915 (2001) 1-13

function varargout = ExponentialGaussian(varargin)

varargout{1} = [];

% ---------------------------------------
% Default
% ---------------------------------------
default.center = 0;
default.width  = 1;

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'x',...
    @(x) validateattributes(x, {'numeric'}, {'nonnan', 'nonempty'}));

addRequired(p, 'y',...
    @(x) validateattributes(x, {'numeric'}, {'nonnan', 'nonempty'}));

addParameter(p, 'center',...
    default.center,...
    @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));

addParameter(p, 'width',...
    default.width,...
    @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));

parse(p, varargin{:});

% ---------------------------------------
% Parse
% ---------------------------------------
x = p.Results.x;
y = p.Results.y;

center = p.Results.center;
width  = p.Results.width;

% ---------------------------------------
% Validate
% ---------------------------------------
if length(x(:,1)) ~= length(y(:,1))
    return
end

if ~isa(x, 'double')
    x = double(x);
end

if ~isa(y, 'double')
    y = double(y);
end

if center == 0
    center = x(find(y == max(y), 1));
    
elseif center > max(x)
    center = max(x) - width/2;
    
elseif center < min(x)
    center = min(x) + width/2;
    
elseif center + width/2 > max(x)
    width = (max(x) - center) * 2;
    
elseif center - width/2 < min(x)
    width = (center - min(x)) * 2;
end

% ---------------------------------------
% Variables
% ---------------------------------------
peaks = {'time', 'width', 'height', 'area', 'fit', 'error'};
peaks = cell2struct(cell(1, length(peaks)), peaks, 2);

% ---------------------------------------
% Peak detection
% ---------------------------------------
peak = PeakDetection(x, y, 'center', center, 'width', width);

% ---------------------------------------
% Exponentially modified gaussian
% ---------------------------------------
EGH.y = @(x, c, h, w, e) h .* exp((-(x-c).^2) ./ ((2.*(w.^2)) + (e.*(x-c))));
EGH.w = @(a, b, alpha) sqrt((-1 ./ (2 .* log(alpha))) .* (a .* b));
EGH.e = @(a, b, alpha) (-1 ./ log(alpha)) .* (b - a);
EGH.a = @(h, w, e, e0) h .* (w .* sqrt(pi/8) + abs(e)) .* e0;
EGH.t = @(w, e) atan(abs(e) ./ w);

EGH.c = @(t) 4.000000 * t^0 + -6.293724 * t^1 + 9.2328340 * t^2 + ...
            -11.34291 * t^3 + 9.1239780 * t^4 + -4.173753 * t^5 + ...
            0.8277970 * t^6;

% ---------------------------------------
% Curve fitting
% ---------------------------------------
for i = 1:length(y(1,:))
    
    % Pre-allocate memory
    peaks.time(i)   = 0;
    peaks.height(i) = 0;
    peaks.width(i)  = 0;
    peaks.area(i)   = 0;
    peaks.fit(:,i)  = zeros(length(y(:,i)),1);
    peaks.error(i)  = 0;
    
    if isempty(peak) || any(peak.center(:,i) == 0)
        continue
    end
    
    % Get peak parameters
    c = peak.center(:,i);
    h = peak.height(:,i);
    w = EGH.w(peak.a(:,i), peak.b(:,i), peak.alpha(:,i));
    e = EGH.e(peak.a(:,i), peak.b(:,i), peak.alpha(:,i));
    
    % Determine limits of function
    lim(:,1) = (2 * w(1)^2) + (e(1) .* (x-c(1))) > 0;
    lim(:,2) = (2 * w(2)^2) + (e(2) .* (x-c(2))) > 0;
    lim(:,3) = (2 * w(1)^2) + (-e(1) .* (x-c(1))) > 0;
    lim(:,4) = (2 * w(2)^2) + (-e(2) .* (x-c(2))) > 0;
    
    % Calculate fit
    yfit  = zeros(length(y(:,i)), 4);
    
    yfit(lim(:,1),1) = EGH.y(x(lim(:,1)), c(1), h(1), w(1), e(1));
    yfit(lim(:,2),2) = EGH.y(x(lim(:,2)), c(2), h(2), w(2), e(2));
    yfit(lim(:,3),3) = EGH.y(x(lim(:,3)), c(1), h(1), w(1), -e(1));
    yfit(lim(:,4),4) = EGH.y(x(lim(:,4)), c(2), h(2), w(2), -e(2));
    
    % Set values outside normal range to zero
    yfit(yfit(:,1) < h(1) * 10^-9 | yfit(:,1) > h(1) * 10, 1) = 0;
    yfit(yfit(:,2) < h(2) * 10^-9 | yfit(:,2) > h(2) * 10, 2) = 0;
    yfit(yfit(:,3) < h(1) * 10^-9 | yfit(:,3) > h(1) * 10, 3) = 0;
    yfit(yfit(:,4) < h(2) * 10^-9 | yfit(:,4) > h(2) * 10, 4) = 0;
    
    % Calculate residuals
    r = repmat(y(:,i), [1,4]) - yfit;
    
    lim(:,1) = x >= c(1)-w(1) & x <= c(1)+w(1);
    lim(:,2) = x >= c(2)-w(2) & x <= c(2)+w(2);
    lim(:,3) = x >= c(1)-w(1) & x <= c(1)+w(1);
    lim(:,4) = x >= c(2)-w(2) & x <= c(2)+w(2);
    
    % Determine fit error
    ymin = min(min(y));
    
    rmsd(1) = sqrt(sum(r(lim(:,1),1).^2) ./ sum(lim(:,1))) / (h(1) - ymin) * 100;
    rmsd(2) = sqrt(sum(r(lim(:,2),2).^2) ./ sum(lim(:,2))) / (h(2) - ymin) * 100;
    rmsd(3) = sqrt(sum(r(lim(:,3),3).^2) ./ sum(lim(:,3))) / (h(1) - ymin) * 100;
    rmsd(4) = sqrt(sum(r(lim(:,4),4).^2) ./ sum(lim(:,4))) / (h(2) - ymin) * 100;
    
    % Determine best fit
    [~, index] = min(rmsd);
    
    if index > 2    
        index = index - 2;
        e = -e(index);
    else
        e = e(index);
    end
    
    % Determine area
    t    = EGH.t(w(index), e);
    e0   = EGH.c(t);
    area = EGH.a(h(index), w(index), e, e0);
    
    if isnan(area) || isnan(rmsd(index))
        continue
    end
    
    % Update values
    peaks.time(i)   = c(index);
    peaks.height(i) = h(index);
    peaks.width(i)  = w(index);
    peaks.area(i)   = area;
    peaks.fit(:,i)  = yfit(:,index);
    peaks.error(i)  = rmsd(index);
    
end

varargout{1} = peaks;

end