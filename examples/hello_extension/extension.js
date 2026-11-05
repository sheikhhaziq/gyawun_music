(ctx) => {
  const API = 'https://jsonplaceholder.typicode.com';

  const thumbs = (seed) => ({
    small: `https://picsum.photos/seed/${seed}/100`,
    medium: `https://picsum.photos/seed/${seed}/300`,
    large: `https://picsum.photos/seed/${seed}/600`,
  });

  async function getJson(path) {
    const res = await ctx.http.fetch(API + path);
    if (res.status !== 200) throw new Error('HTTP ' + res.status + ' for ' + path);
    return JSON.parse(res.body);
  }

  const toItem = (post) => ({
    kind: 'song',
    title: post.title.slice(0, 40),
    subtitle: 'Post #' + post.id,
    thumbnails: thumbs('post' + post.id),
    artists: [{ name: 'User ' + post.userId, browse: { screen: 'user', id: post.userId } }],
    play: { action: 'play', id: post.id },
    radio: { action: 'radio', id: post.id },
  });

  async function home() {
    ctx.log.info('loading home');
    const posts = await getJson('/posts?_limit=12');
    await ctx.storage.set('lastHomeCount', posts.length);

    return {
      header: {
        title: 'Hello Extension',
        description: 'Fake data from jsonplaceholder',
        thumbnails: thumbs('header'),
      },
      chips: [
        { text: 'Recent', endpoint: { screen: 'recent' } },
        { text: 'Popular', endpoint: { screen: 'popular' } },
      ],
      sections: [
        {
          title: 'Trending',
          style: 'horizontal',
          action: { type: 'play', endpoint: { action: 'play', section: 'trending' } },
          items: posts.slice(0, 6).map(toItem),
        },
        {
          title: 'More to explore',
          style: 'vertical',
          action: { type: 'browse', endpoint: { action: 'items', section: 'more' } },
          items: posts.slice(6, 12).map(toItem),
        },
      ],
      continuation: { page: 2 },
    };
  }

  return {
    // browse() = home screen. browse(endpoint) = a chip, artist or continuation.
    browse: async (endpoint) => {
      if (!endpoint) return home();
      ctx.log.info('browse endpoint', endpoint);
      if (endpoint.page) {
        const posts = await getJson('/posts?_start=12&_limit=6');
        return {
          sections: [{ title: 'Page ' + endpoint.page, style: 'vertical', items: posts.map(toItem) }],
        };
      }
      return { sections: [{ title: 'Screen: ' + endpoint.screen, style: 'vertical', items: [] }] };
    },

    // Handy for checking storage and logging from the debug screen.
    stats: async () => ({
      lastHomeCount: await ctx.storage.get('lastHomeCount'),
      keys: await ctx.storage.keys(),
    }),
  };
}