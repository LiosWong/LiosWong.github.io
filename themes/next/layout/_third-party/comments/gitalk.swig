{% if page.comments && theme.gitalk.enable %}
  <link rel="stylesheet" href="https://unpkg.com/gitalk/dist/gitalk.css">

  <script src="https://unpkg.com/gitalk/dist/gitalk.min.js"></script>
   <script type="text/javascript">
        var gitalk = new Gitalk({
          clientID: '{{ theme.gitalk.client_id }}',
          clientSecret: '{{ theme.gitalk.client_secret }}',
          repo: '{{ theme.gitalk.repo }}',
          owner: '{{ theme.gitalk.github_id }}',
          admin: ['{{ theme.gitalk.admin_user }}'],
          id: decodeURI(location.pathname),
          distractionFreeMode: '{{ theme.gitalk.distractionFreeMode }}'
        })
        gitalk.render('gitalk-container')
       </script>
{% endif %}
