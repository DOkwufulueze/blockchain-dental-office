import gravatar from 'gravatar-api'

function getGravatarImage (email = '') {
  const gravatarOptions = {
    email: email,
    parameters: { 'size': '104', 'd': 'mm' },
    secure: true
  }

  const avatar = email && email.trim() !== '' ? gravatar.imageUrl(gravatarOptions) : null
  return avatar
}

export const avatarCanvasElement = function (email) {
  return new Promise(function (resolve, reject) {
    const image = new Image()
    image.src = getGravatarImage(email)
    image.addEventListener('load', function () {
      const avatarCanvas = document.createElement('canvas')
      const avatarContext = avatarCanvas.getContext('2d')
      avatarCanvas.height = this.height
      avatarCanvas.width = this.width
      avatarContext.drawImage(this, 0, 0, this.width, this.height)
      resolve(avatarCanvas)
    })
  })
}
