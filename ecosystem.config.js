module.exports = {
  /**
   * Application configuration section
   * http://pm2.keymetrics.io/docs/usage/application-declaration/
   */
  apps : [

    {
      name      : 'reputation:3440',
      script    : 'serve_reputation.coffee',
      cwd       : '/home/considerit/considerit-lab',
      max_restarts: 2,
      restart_delay: 1000
    },
    {
      name      : 'deslider',
      script    : 'serve_multicriteria.coffee',
      cwd       : '/home/considerit/considerit-lab',
      max_restarts: 2,
      restart_delay: 1000
    },
    {
      name      : 'nested:3006',
      script    : 'serve_nested.coffee',
      cwd       : '/home/considerit/considerit-lab',
      max_restarts: 2,
      restart_delay: 1000
    },
    {
      name      : 'slideboard',
      script    : 'serve_slideboard.coffee',
      cwd       : '/home/considerit/considerit-lab',
      max_restarts: 2,
      restart_delay: 1000
    },
    {
      name      : 'lists:9376',
      script    : 'serve_lists.coffee',
      cwd       : '/home/considerit/considerit-lab',
      max_restarts: 2,
      restart_delay: 1000
    },
    {
      name      : 'blog:8106',
      script    : 'serve_blog.coffee',
      cwd       : '/home/considerit/considerit-lab',
      max_restarts: 2,
      restart_delay: 1000
    },
    {
      name      : 'discuss:3606',
      script    : 'serve_discuss.coffee',
      cwd       : '/home/considerit/considerit-lab',
      max_restarts: 2,
      restart_delay: 1000
    },

  ]

};