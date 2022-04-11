%Image Aquesition
%Read the image in.
l=0;
Image=imread('C:/Users/Marcus/Documents/starfish_images/starfish.jpg');
%Adjust the contrast of the image to make the starfish stand out more
subplot(3,3,1);
imshow(Image);
title('Original Image');
Starfish = imadjust(Image,[0.70 1]);
%Reduce the brightness of the rgb starfish image as it is far too bright
Starfish = Starfish-125;
subplot(3,3,2);
imshow(Starfish);
title({'Contrast and Brightness','Adjusted'});
%Split the image into three channels
rchannel = Starfish(:, :, 1);
gchannel = Starfish(:, :, 2);
bchannel = Starfish(:, :, 3);
%The green channel was selected as the primary binary image to use as no
%starfish are seen in the red channel and blue was slightly worse than
%green
subplot(3,3,3);
imshow(gchannel);
title('Default green channel');
%Image Restoration
%A 2x2 kernel is created and a mean filter is applied to the green channel
H = fspecial('average', [2 2]);
I = imfilter(gchannel, H);
gchannel = wiener2(gchannel,[6 6]);
%Two more filters are then applied to the green channel as to reduce the
%noise in the image.
gchannel = imfilter(gchannel,H);
gchannel = medfilt2(gchannel);
subplot(3,3,4);
imshow(gchannel);
title('Cleaned green channel');
%The green channel has its colour values reduced to 20 or below this
%reduces the amount of random objects on screen and highlights the starfish
%as well as seashells on the screen.
gchannel = gchannel<20;
subplot(3,3,5);
imshow(gchannel);
title({'image intensity reduced to', 'only show certain objects'});
%The green channel is then scanned for edges and a thing is done to reduce
%smaller objects from appearing and leaves the 5 starfish and 4 seashells
imedgeg = edge(gchannel,'canny');
imedgeg = bwareaopen(imedgeg, 150);
subplot(3,3,7);
imshow(imedgeg);
title('Edge detection');
filledImage = imfill(imedgeg, 'holes');
filledImage = bwlabel(filledImage);
subplot(3,3,6)
imshow(filledImage);
title({'image has holes', 'filled to reduce small objects'});
coloredLabels = label2rgb (filledImage, 'hsv', 'k', 'shuffle'); % pseudo random color labels
% coloredLabels is an RGB image.  We could have applied a colormap instead (but only with R2014b and later)
subplot(3, 3, 8);
imshow(coloredLabels);
title('Starfish segmented');
%Feature Detection and Extraction
%A feature detector and extractor are then implemented
subplot(3,3,9);
imshow(imedgeg);
title('Feature Detection')
%obtains all of the corners in the image
corners = detectHarrisFeatures(imedgeg);
hold on;
%plots the 50 strongest corners
plot(corners.selectStrongest(50));
[features, valid_corners] = extractFeatures(gchannel, corners);
plot(valid_corners);
%Shape Detection
properties = regionprops(imedgeg, 'all');
[nregions, ~] = size(properties);
[height,width,~] = size(Image);
maskall = false(size(imedgeg));
maxl = sqrt(height^2 + width^2);
%for loop to loop around all objects in image
for i = 1:nregions
    cogx = properties(i).Centroid(1);
    cogy = properties(i).Centroid(2);
    %set arc lengths to 0 to reset during the next loops
    arcsum = 0;
    arcn = 0;
    minarc = maxl;
    maxarc = 0;
    mask = false(size(imedgeg));
    [pixels, ~] = size(properties(i).PixelList);
    for j = 1:pixels
        x = properties(i).PixelList(j,1);
        y = properties(i).PixelList(j,2);
        mask(y, x) = true;
    end
    [rows, columns] = find(bwperim(mask));
    [pcount, ~] = size( columns );
    for j = 1:pcount
        x = columns( j );
        y = rows( j );

        arc = sqrt( (cogx-x)^2 + (cogy-y)^2 );
        arcsum = arcsum + arc;
        %check is arc is greater than minimum arc
        if (arc < minarc)
            minarc = arc;    
        end
        %checks if arc is greater than maxarc
        if (arc > maxarc)
            maxarc = arc;    
        end
    end
    %Calculating the rationmix and max
    maskall = maskall + mask;
    meanarc = arcsum/pcount;
    minarc;
    maxarc;
    rationmin = minarc/meanarc;
    rationmax = maxarc/meanarc;
    %a meanarc of less than 19 and greater than 15 was determine to be the
    %appropriate meanarc for a starshape
    %So if the object is between these meanarc parameters it is categorised
    %as a starfish
    if (meanarc < 19 && meanarc > 15)
            hold on;
            %The objects are then placed in a bounding box and layered over
            %the original image to show where the starfish are
            L = bwlabel(mask);
                s = regionprops(L, 'Area', 'BoundingBox');
                area_values = [s.Area];
                idx = find((100 <= area_values) & (area_values <= 1000));
            newmask = mask;
            figure(3)
            %the l is incremented to count the number of starfish and put
            %the number in the title
            l=l+1;
            subplot(3,3,l);
            imshow(Starfish);
            bb = s(idx).BoundingBox;
            rectangle('Position',[bb(1) bb(2) bb(3) bb(4)],'EdgeColor','green');
            hold off;
    end
    figure(3)
    title(['This is Starfish #',sprintf('%d',l)]);
end