(function($)
{
    $.fn.ShuffleText = function(strings, options) {


        function striphtml(html)
        {
            var tmp = document.createElement("DIV");
            tmp.innerHTML = html;
            return tmp.textContent || tmp.innerText || "";
        }

        var self= this;

        if (typeof strings !== 'object') { throw new TypeError('You must pass an array of strings in the first parameter');}

        $(self).html(strings[0]);

        var loop = options.loop || false,
            iterations = options.iterations || 50,
            delay = options.delay || 3000,
            step = options.step || function() {},
            shuffleSpeed = options.shuffleSpeed || 0;

        if (typeof options === 'function') {
            var callback = options;
        }
        else {
            var callback = options.callback || function() {};
        }

        var iterateString = function(index) {

            $(self).html(strings[index]);

            var morpher = function(i){
                //Randomize each char of the current strin, add/remove letters during shuffle, etc
                var string = '';
                if (index === 0) {
                    var mask = striphtml(strings[strings.length-1] + strings[index]).split('');
                    var diffLength= Math.floor((striphtml(strings[index]).length - striphtml(strings[strings.length-1]).length) / iterations * i);
                    var last= striphtml(strings[strings.length-1]).length;

                }
                else {
                    var mask = striphtml(strings[index - 1] + strings[index]).split('');
                    var diffLength= Math.floor((striphtml(strings[index]).length - striphtml(strings[index-1]).length) / iterations * i);
                    var last= striphtml(strings[index-1]).length;
                }


                for (var j = 0; j < last + diffLength; j++) {
                    var rand = Math.floor(Math.random() * mask.length),
                    randomLetter = mask[rand];
                    string+= randomLetter;
                }
                $(self).html(string);

                //iterate..
                if (i !== iterations) {
                    setTimeout(function(){
                        morpher(i + 1 );
                    },shuffleSpeed);
                }
                else {

                    $(self).html(strings[index]);
                    step(strings[index]);

                    if (index !== strings.length - 1) {
                        setTimeout(function(){
                            iterateString(index + 1);
                        },delay)
                    }
                    else {
                        if (loop){

                            setTimeout(function(){
                                iterateString(0);
                            },delay)
                        }
                    }
                }
            };
                morpher(0);




        };
        setTimeout(function(){
            iterateString(1);
        }, delay);

    }
})(jQuery);


