$(document).ready(function() {
    // Message to console
    console.log("GitHub image cache");

    // Count how many img elements are there
    var imgCount = $("article img").length,
        switchCount = 0,
        suffix;
    
    // Do URL switch only if needed
    if(imgCount > 0) {
        
        // Handle each image
        $("article img").each(function(){
            // Get the real URL ...
            var noCacheURL = $(this).data("canonical-src");
            // .. and switch it's place.
            $(this).attr("src", noCacheURL);
            
            switchCount++;
        });
        
        if(switchCount > 0) {
            suffix = "s";
        }
        
        console.log(switchCount + " URL" + suffix + " switched.");
        
    } else {
        
        // Show message saying no images.
        console.log("No images found. No need to prevent cache.");
    } 
});
                  