export function contracts() {
    return {
      name: 'contracts',
      resolveId(id) {
        if (id.startsWith('contracts/')) {
          return id
        }
      }
    }
  }