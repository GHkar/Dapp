$(function() {
    $(window).load(function() {
    App.init();
    });
});

App = {
    init: function(){
        $(document).on('click', '#logout', App.logout);
    },
    logout : function(event){
        //sessionStorage.clear();
    }
}